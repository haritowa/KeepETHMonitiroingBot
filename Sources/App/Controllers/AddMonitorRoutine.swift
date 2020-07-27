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
            .flatMapError(sendAddMonitorErrorMessage(with: request, chatID: telegramID))
    }
    
    private static func validateETHAddress(eventLoop: EventLoop, address: String) -> EventLoopFuture<EthereumAddress> {
        eventLoop.tryFuture {
            guard let ethAddress = EthereumAddress(hexString: address) else { throw Error.invalidAddress(address) }
            return ethAddress
        }
    }
    
    private static func fetchCurrentBalance(request: Request) -> (EthereumAddress) -> EventLoopFuture<Double> {
        return { address in
            request.keepClient.unbondedValue(operatorAddress: address)
                .map { $0.ethSecondDigitPericion }
        }
    }
    
    private static func addMonitorModelWith(request: Request, for telegramID: Int, address: String, ethThreshold: UInt) -> (Double) -> EventLoopFuture<(AlertMonitor, Double)> {
        return { ethValue in
            let model = AlertMonitor(telegramDialogueID: telegramID, operatorAddress: address, ethThreshold: ethThreshold)
            
            return model.create(on: request.db)
                .flatMapErrorThrowing { _ in throw Error.cantCreateModel }
                .map { _ in (model, ethValue) }
        }
    }
    
    private static func successMessage(for alertMonitor: AlertMonitor, ethValue: Double) -> String {
        return "Successfully created monitor for \(alertMonitor.operatorAddress). Your current unbondend ETH value is \(ethValue)"
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
}
