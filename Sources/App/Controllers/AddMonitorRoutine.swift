//
//  AddMonitorRoutine.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor

import Fluent
import Web3

import BigInt

struct AddMonitorRoutine {
    enum Error: Swift.Error {
        case invalidAddress(String)
        case cantCreateModel
    }
    
    static func addMonitor(request: Request, for telegramID: Int, address: String, ethThreshold: UInt) -> EventLoopFuture<Void> {
        validateETHAddress(eventLoop: request.eventLoop, address: address)
            .flatMap(fetchCurrentBalance(request: request))
            .flatMap(addMonitorModelWith(request: request, for: telegramID, address: address, ethThreshold: ethThreshold))
            .flatMap(sendAddMonitorSuccessMessage(with: request))
            .flatMap { checkSortitionPoolAuth(request: request, telegramID: telegramID, address: address) }
            .flatMapError(sendAddMonitorErrorMessage(with: request, chatID: telegramID))
    }
    
    private static func validateETHAddress(eventLoop: EventLoop, address: String) -> EventLoopFuture<EthereumAddress> {
        eventLoop.tryFuture {
            do {
                return try EthereumAddress(hex: address, eip55: true)
            } catch {
                throw Error.invalidAddress(address)
            }
        }
    }
    
    private static func fetchCurrentBalance(request: Request) -> (EthereumAddress) -> EventLoopFuture<Double> {
        return { address in
            request.keepClient.unbondedValue(operatorAddress: address)
                .map { $0.ethSecondDigitPericion }
        }
    }
    
    private static func getMonitorForUser(request: Request, for telegramID: Int, address: String, ethThreshold: UInt) -> EventLoopFuture<AlertMonitor?> {
        AlertMonitor.query(on: request.db)
            .filter(\.$operatorAddress == address)
            .filter(\.$telegramDialogueID == telegramID)
            .first()
    }
    
    private static func createOrUpdateMonitorWith(request: Request, for telegramID: Int, address: String, ethThreshold: UInt) -> EventLoopFuture<AlertMonitor> {
        getMonitorForUser(request: request, for: telegramID, address: address, ethThreshold: ethThreshold).flatMap { monitor in
            if let monitor = monitor {
                monitor.ethThreshold = ethThreshold
                monitor.latestReportedValue = nil
                return monitor.save(on: request.db).map { monitor }
            } else {
                let newMonitor = AlertMonitor(telegramDialogueID: telegramID, operatorAddress: address, ethThreshold: ethThreshold)
                return newMonitor.create(on: request.db).map { newMonitor }
            }
        }
    }
    
    private static func addMonitorModelWith(request: Request, for telegramID: Int, address: String, ethThreshold: UInt) -> (Double) -> EventLoopFuture<(AlertMonitor, Double)> {
        return { ethValue in
            createOrUpdateMonitorWith(request: request, for: telegramID, address: address, ethThreshold: ethThreshold)
                .map { ($0, ethValue) }
                .flatMapErrorThrowing { _ in throw Error.cantCreateModel }
        }
    }
    
    private static func successMessage(for alertMonitor: AlertMonitor, ethValue: Double) -> String {
        return "I'll notify you when \(createEtherscanLink(for: alertMonitor.operatorAddress)) unbounded ETH will be lower than \(alertMonitor.ethThreshold).\nCurrently you have *\(ethValue)* unbounded ETH."
    }
    
    private static func sendAddMonitorSuccessMessage(with request: Request) -> ((AlertMonitor, Double)) -> EventLoopFuture<Void> {
        return { pair in
            let (monitor, ethValue) = pair
            
            return request.telegramClient.sendMessage(
                chatID: monitor.telegramDialogueID,
                text: successMessage(for: monitor, ethValue: ethValue)
            )
        }
    }
    
    private static func errorMessage(for error: Swift.Error) -> String {
        guard let error = error as? Error else { return "Unknown error. Check your current monitors list and try again later" }
        
        switch error {
        case .invalidAddress: return "Specified ETH address is incorrect. Double check your input"
        case .cantCreateModel: return "Something went wrong"
        }
    }
    
    private static func sendAddMonitorErrorMessage(with request: Request, chatID: Int) -> (Swift.Error) -> EventLoopFuture<Void> {
        return { error in
            let message = errorMessage(for: error)
            return request.telegramClient.sendMessage(chatID: chatID, text: message)
        }
    }
    
    // MARK: - TBTC Auth Check
    private static func checkSortitionPoolAuth(request: Request, telegramID: Int, address: String) -> EventLoopFuture<Void> {
        guard let ethAddress = EthereumAddress(hexString: address) else {
            return request.eventLoop.future()
        }
        
        return request.keepClient.hasTBTCAuthorization(operatorAddress: ethAddress)
            .flatMap(sendSortitionResultMessage(with: request, telegramID: telegramID, address: address))
    }
    
    private static func sendSortitionGrantedMessage(with request: Request, telegramID: Int, address: String) -> EventLoopFuture<Void> {
        let message = "✅ Operator \(createEtherscanLink(for: address)) has TBTC authorization and ready to work!"
        return request.telegramClient.sendMessage(chatID: telegramID, text: message)
    }
    
    private static func sendSortitionNotAuthorizedMessage(with request: Request, telegramID: Int, address: String) -> EventLoopFuture<Void> {
        let dashboardURL = URL(string: "https://dashboard.test.keep.network/applications/tbtc")!
        let message = "⁉️ Operator \(createEtherscanLink(for: address)) does not have TBTC authorization. You can grant authorization using dashboard."
        
        let replyMarkup = TelegramClientReplyMarkup.inlineReply(
            TelegramInlineKeyboardMarkup(inlineKeyboard: [
                [
                    .init(text: "Go to dashboard", url: dashboardURL)
                ]
            ])
        )
        
        return request.telegramClient.sendMessage(chatID: telegramID, text: message, replyMarkup: replyMarkup)
    }
    
    private static func sendSortitionCantGetPoolMessage(with request: Request, telegramID: Int, address: String) -> EventLoopFuture<Void> {
        let dashboardURL = URL(string: "https://dashboard.test.keep.network/applications/tbtc")!
        let message = "⚠️ Can't get sortion pool for \(createEtherscanLink(for: address)). Check your ECDSAKeepFactory authorization."
        
        let replyMarkup = TelegramClientReplyMarkup.inlineReply(
            TelegramInlineKeyboardMarkup(inlineKeyboard: [
                [
                    .init(text: "Go to dashboard", url: dashboardURL)
                ]
            ])
        )
        
        return request.telegramClient.sendMessage(chatID: telegramID, text: message, replyMarkup: replyMarkup)
    }
    
    private static func sendSortitionResultMessage(with request: Request, telegramID: Int, address: String) -> (KeepTBTCAuthResult) -> EventLoopFuture<Void> {
        return { result -> EventLoopFuture<Void> in
            switch result {
            case .uknownError: return request.eventLoop.future()
            case .granted: return sendSortitionGrantedMessage(with: request, telegramID: telegramID, address: address)
            case .notAuthorized: return sendSortitionNotAuthorizedMessage(with: request, telegramID: telegramID, address: address)
            case .cantGetSoritonPool: return sendSortitionCantGetPoolMessage(with: request, telegramID: telegramID, address: address)
            }
        }
    }
}
