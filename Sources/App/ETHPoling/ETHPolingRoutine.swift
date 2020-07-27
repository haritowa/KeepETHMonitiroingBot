//
//  ETHPolingRoutine.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor
import Fluent
import Web3

private typealias ETHUnboundedTokensBatchResult = [String: Double]

struct ETHPolingRoutine {
    static func performMonitoring(request: Request) -> EventLoopFuture<Void> {
        getAllETHAddresses(database: request.db)
            .map(toEtherumAddress)
            .flatMap(request.keepClient.unbondedValues)
            .map(ethFetchResultWithEthMagnitude)
            .flatMap(sendNotifications(request: request))
    }
    
    private static func getAllETHAddresses(database: Database) -> EventLoopFuture<[String]> {
        AlertMonitor
            .query(on: database)
            .field(\.$operatorAddress)
            .unique()
            .all(\.$operatorAddress)
    }
    
    private static func toEtherumAddress(operators: [String]) -> [EthereumAddress] {
        operators.compactMap(EthereumAddress.init(hexString:))
    }
    
    private static func ethFetchResultWithEthMagnitude(batchResult: KeepUnboundedTokensFetchBatchResult) -> ETHUnboundedTokensBatchResult {
        var result = [String: Double]()
        
        for (key, value) in batchResult {
            result[key.hex(eip55: true)] = value.ethSecondDigitPericion
        }
        
        return result
    }
    
    private static func getMonitors(db: Database, for address: String, ethValue: UInt) -> EventLoopFuture<[AlertMonitor]> {
        AlertMonitor
            .query(on: db)
            .filter(\.$operatorAddress == address)
            .filter(\.$ethThreshold >= ethValue)
            .all()
    }
    
    private static func sendNotification(
        telegramClient: TelegramClientProtocol,
        triggeredMonitor: AlertMonitor,
        unboundedETH: Double
    ) -> EventLoopFuture<Void> {
        let message = "Low available ETH alert triggered for \(triggeredMonitor.operatorAddress). (\(unboundedETH) is equal or lower than \(triggeredMonitor.ethThreshold) ETH)"
        return telegramClient.sendMessage(chatID: triggeredMonitor.telegramDialogueID, text: message)
    }
    
    private static func sendNotifications(request: Request, unboundedETH: Double) -> ([AlertMonitor]) -> EventLoopFuture<Void> {
        return { monitors in
            let futures = monitors.map { sendNotification(telegramClient: request.telegramClient, triggeredMonitor: $0, unboundedETH: unboundedETH) }
            
            return EventLoopFuture.whenAllComplete(futures, on: request.eventLoop)
                .map { _ in () }
        }
    }
    
    private static func sendNotifications(request: Request, address: String, unboundedETH: Double) -> EventLoopFuture<Void> {
        let ethValue = UInt(ceil(unboundedETH))
        
        return getMonitors(db: request.db, for: address, ethValue: ethValue)
            .flatMap(sendNotifications(request: request, unboundedETH: unboundedETH))
    }
    
    private static func sendNotifications(request: Request) -> (ETHUnboundedTokensBatchResult) -> EventLoopFuture<Void> {
        return { fetchResult in
            let operations = fetchResult.map { pair in sendNotifications(request: request, address: pair.key, unboundedETH: pair.value) }
            
            return EventLoopFuture.whenAllComplete(operations, on: request.eventLoop)
                .map { _ in () }
        }
    }
}
