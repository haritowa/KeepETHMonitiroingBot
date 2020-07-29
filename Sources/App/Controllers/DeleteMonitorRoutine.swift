//
//  DeleteMonitorRoutine.swift
//  
//
//  Created by Anton Kharchenko on 7/29/20.
//

import Foundation
import Vapor
import Fluent

struct DeleteMonitorRoutine {
    private enum Error: Swift.Error {
        case zeroMatchedOperators
        case severalMatchedOperators
    }
    
    static func perform(with request: Request, telegramID: Int, addressQuery: String) -> EventLoopFuture<Void> {
        findOperator(in: request.db, telegramID: telegramID, for: addressQuery)
            .flatMap(deleteOperator(from: request.db))
            .flatMap(sendSuccessMessage(using: request.telegramClient, chatID: telegramID))
            .flatMapError(sendErrorMesage(using: request.telegramClient, chatID: telegramID))
    }
    
    private static func findOperator(in db: Database, telegramID: Int, for query: String) -> EventLoopFuture<AlertMonitor> {
        AlertMonitor.query(on: db)
        .filter(\.$telegramDialogueID == telegramID)
        .filter(\.$operatorAddress =~ query)
        .all()
        .flatMapThrowing { result in
            switch result.count {
            case 0: throw Error.zeroMatchedOperators
            case 1: return result[0]
            default: throw Error.severalMatchedOperators
            }
        }
    }
    
    private static func deleteOperator(from db: Database) -> (AlertMonitor) -> EventLoopFuture<String> {
        return { monitor in
            let address = monitor.operatorAddress
            return monitor.delete(on: db).map { address }
        }
    }
    
    private static func sendSuccessMessage(using telegramClient: TelegramClientProtocol, chatID: Int) -> (String) -> EventLoopFuture<Void> {
        return { operatorAddress in
            let message = "Alert for \(createEtherscanLink(for: operatorAddress)) deleted"
            return telegramClient.sendMessage(chatID: chatID, text: message)
        }
    }
    
    private static func mapErrorMessage(for error: Swift.Error) -> String {
        guard let fetchError = error as? Error else {
            return "Unknown error occured. Try again later."
        }
        
        switch fetchError {
        case .zeroMatchedOperators: return "None of your operators match this query"
        case .severalMatchedOperators: return "Several operators match your query, add several more address symbols"
        }
    }
    
    private static func sendErrorMesage(using telegramClient: TelegramClientProtocol, chatID: Int) -> (Swift.Error) -> EventLoopFuture<Void> {
        return { error in
            let message = mapErrorMessage(for: error)
            return telegramClient.sendMessage(chatID: chatID, text: message)
        }
    }
}
