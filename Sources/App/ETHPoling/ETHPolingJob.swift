//
//  ETHPolingJob.swift
//  
//
//  Created by Anton Kharchenko on 7/28/20.
//

import Foundation

import Vapor
import Queues

import Fluent
import Web3

private typealias ETHUnbondedTokensBatchResult = [String: Double]

struct ETHPolingJob: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        Self.performMonitoring(
            db: context.application.db,
            keepClient: context.application.keepClient,
            telegramClient: context.application.telegramClient,
            eventLoop: context.eventLoop
        )
    }
    
    private static func performMonitoring(
        db: Database,
        keepClient: KeepClientProtocol,
        telegramClient: TelegramClientProtocol,
        eventLoop: EventLoop
    ) -> EventLoopFuture<Void> {
        getAllETHAddresses(database: db)
            .map(toEtherumAddress)
            .flatMap(keepClient.unbondedValues)
            .map(ethFetchResultWithEthMagnitude)
            .flatMap(sendNotifications(db: db, telegramClient: telegramClient, eventLoop: eventLoop))
    }
    
    private static func getAllETHAddresses(database: Database) -> EventLoopFuture<[String]> {
        AlertMonitor
            .query(on: database)
            .field(\.$operatorAddress)
            .unique()
            .all(\.$operatorAddress)
    }
    
    private static func toEtherumAddress(operators: [String]) -> [EthereumAddress] {
        operators.compactMap { try? EthereumAddress(hex: $0, eip55: false) }
    }
    
    private static func ethFetchResultWithEthMagnitude(batchResult: KeepUnbondedTokensFetchBatchResult) -> ETHUnbondedTokensBatchResult {
        var result = [String: Double]()
        
        for (key, value) in batchResult {
            result[key.hex(eip55: true)] = value.ethSecondDigitPericion
        }
        
        return result
    }
    
    private static func resetLatestReportedValuesForNonMatchinMonitors(
        db: Database,
        address: String,
        ethValue: UInt
    ) -> EventLoopFuture<Void> {
        db.transaction { transaction in
            let allNonTriggeredMonitors = AlertMonitor.query(on: transaction)
                .filter(\.$operatorAddress == address)
                .filter(\.$ethThreshold < ethValue)
                .filter(\.$latestReportedValue != nil)
                .all()
            
            return allNonTriggeredMonitors.flatMapEach(on: transaction.eventLoop) { monitor -> EventLoopFuture<Void> in
                monitor.latestReportedValue = nil
                return monitor.save(on: transaction)
            }.map { _ in () }
        }.flatMapErrorThrowing { _ in () }
    }
    
    private static func getMonitors(db: Database, for address: String, ethValue: UInt) -> EventLoopFuture<[AlertMonitor]> {
        AlertMonitor
            .query(on: db)
            .filter(\.$operatorAddress == address)
            .filter(\.$ethThreshold >= ethValue)
            .group(.or) { $0.filter(\.$latestReportedValue != ethValue).filter(\.$latestReportedValue == nil) }
            .all()
    }
    
    private static func sendNotification(
        telegramClient: TelegramClientProtocol,
        triggeredMonitor: AlertMonitor,
        db: Database,
        unbondedETH: Double
    ) -> EventLoopFuture<Void> {
        let message = "Operator \(createEtherscanLink(for: triggeredMonitor.operatorAddress)) is low on unbonded ETH(*\(unbondedETH)*)"
        return telegramClient.sendMessage(chatID: triggeredMonitor.telegramDialogueID, text: message)
            .flatMap { triggeredMonitor.latestReportedValue = normalize(eth: unbondedETH); return triggeredMonitor.save(on: db) }
    }
    
    private static func sendNotifications(
        unbondedETH: Double,
        db: Database,
        telegramClient: TelegramClientProtocol,
        eventLoop: EventLoop
    ) -> ([AlertMonitor]) -> EventLoopFuture<Void> {
        return { monitors in
            let futures = monitors.map { sendNotification(telegramClient: telegramClient, triggeredMonitor: $0, db: db, unbondedETH: unbondedETH) }
            
            return EventLoopFuture.whenAllComplete(futures, on: eventLoop)
                .map { _ in () }
        }
    }
    
    private static func normalize(eth: Double) -> UInt {
        UInt(ceil(eth))
    }
    
    private static func sendNotifications(
        address: String,
        unbondedETH: Double,
        db: Database,
        telegramClient: TelegramClientProtocol,
        eventLoop: EventLoop
    ) -> EventLoopFuture<Void> {
        let ethValue = normalize(eth: unbondedETH)
        
        return resetLatestReportedValuesForNonMatchinMonitors(db: db, address: address, ethValue: ethValue)
            .flatMap { getMonitors(db: db, for: address, ethValue: ethValue) }
            .flatMap(sendNotifications(unbondedETH: unbondedETH, db: db, telegramClient: telegramClient, eventLoop: eventLoop))
    }
    
    private static func sendNotifications(
        db: Database,
        telegramClient: TelegramClientProtocol,
        eventLoop: EventLoop
    ) -> (ETHUnbondedTokensBatchResult) -> EventLoopFuture<Void> {
        return { fetchResult in
            let operations = fetchResult.map { pair in
                sendNotifications(
                    address: pair.key,
                    unbondedETH: pair.value,
                    db: db,
                    telegramClient: telegramClient,
                    eventLoop: eventLoop
                )
            }
            
            return EventLoopFuture.whenAllComplete(operations, on: eventLoop)
                .map { _ in () }
        }
    }
}
