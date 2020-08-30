//
//  CollateralizationFetchJob.swift
//  
//
//  Created by Anton Kharchenko on 8/30/20.
//

import Foundation

import Vapor
import Fluent
import Web3

import Queues

struct CollateralizationAlertsOperation {
    private static let callLength = TimeInterval(60*60*6)
    
    private let telegramClient: TelegramClientProtocol
    private let keepClient: KeepClientProtocol
    private let web3: Web3
    private let db: Database
    private let eventLoop: EventLoop
    
    init(
        telegramClient: TelegramClientProtocol,
        keepClient: KeepClientProtocol,
        web3: Web3,
        db: Database,
        eventLoop: EventLoop
    ) {
        self.telegramClient = telegramClient
        self.keepClient = keepClient
        self.web3 = web3
        self.db = db
        self.eventLoop = eventLoop
    }
    
    func run() -> EventLoopFuture<Void> {
        let fetchResult = getLastKnownBlock().flatMap {
            CollateralizationFetchRoutine(
                fromBlock: $0,
                eventLoop: self.eventLoop,
                web3: self.web3,
                keepClient: self.keepClient
            ).perform()
        }
        
        return fetchResult.flatMap(run)
    }
    
    private func run(fetchResult: CollateralizationPollingFetchResult) -> EventLoopFuture<Void> {
        getAllMatchingAllerts(for: Set(fetchResult.alerts.keys))
            .flatMap { self.sendAlert(fetchResult: fetchResult, monitors: $0) }
            .flatMap { self.storeLastKnownBlock(block: fetchResult.latestBlock) }
    }
    
    private func getLastKnownBlock() -> EventLoopFuture<EthereumQuantityTag> {
        CollateralizationLastKnownBlock
        .query(on: db)
        .sort(\.$date, .descending)
        .first()
        .map { lastKnownBlock in
            guard let lastKnownBlock = lastKnownBlock, let blockIndex = BigUInt(hexString: lastKnownBlock.blockNumber) else {
                return EthereumQuantityTag.earliest
            }
            
            return EthereumQuantityTag.block(blockIndex)
        }
    }
    
    private func storeLastKnownBlock(block: String?) -> EventLoopFuture<Void> {
        guard let block = block else { return eventLoop.makeSucceededFuture(()) }
        
        return CollateralizationLastKnownBlock(
            blockNumber: block,
            date: Date()
        ).save(on: db)
    }
    
    private func getAllMatchingAllerts(
        for operators: Set<String>
    ) -> EventLoopFuture<[AlertMonitor]> {
        AlertMonitor
            .query(on: db)
            .filter(\.$operatorAddress ~~ operators)
            .field(\.$telegramDialogueID)
            .field(\.$operatorAddress)
            .all()
    }
    
    private func sendAlert(
        fetchResult: CollateralizationPollingFetchResult,
        monitors: [AlertMonitor]
    ) -> EventLoopFuture<Void> {
        let work = monitors.flatMap { monitor -> [EventLoopFuture<Void>] in
            guard let alerts = fetchResult.alerts[monitor.operatorAddress] else {
                return []
            }
            
            return alerts.map { self.send(alert: $0, for: monitor) }
        }
        
        return EventLoopFuture.andAllSucceed(work, on: eventLoop)
    }
    
    // MARK: - Telegram
    func undercollateralizedText(for alert: FetchedCollateralizationAlert) -> String {
        let operatorAddress = alert.operatorAddress.hex(eip55: true)
        let depositAddress = alert.depositAddress.hex(eip55: true)
        
        let endDate = alert.date.addingTimeInterval(Self.callLength)
        let remainingInterval = endDate.timeIntervalSince(Date())
        
        return "⚠️ Your operator \(createEtherscanLink(for: operatorAddress)) have undercollateralized deposit \(createEtherscanLink(for: depositAddress)). \(remainingInterval.formatted) until auction starts"
    }
    
    func severelyUndercollateralizedText(for alert: FetchedCollateralizationAlert) -> String {
        let operatorAddress = alert.operatorAddress.hex(eip55: true)
        let depositAddress = alert.depositAddress.hex(eip55: true)
        
        return "‼️ Your operator \(createEtherscanLink(for: operatorAddress)) have severely undercollateralized deposit \(createEtherscanLink(for: depositAddress))"
    }
    
    private func send(
        alert: FetchedCollateralizationAlert,
        for monitor: AlertMonitor
    ) -> EventLoopFuture<Void> {
        let docsURL = URL(string: "https://docs.keep.network/tbtc/index.html#pre-liquidation")!
        let message = alert.isSeverelyUndercollateralized ? severelyUndercollateralizedText(for: alert) : undercollateralizedText(for: alert)
        
        let replyMarkup = TelegramClientReplyMarkup.inlineReply(
            TelegramInlineKeyboardMarkup(inlineKeyboard: [
                [
                    .init(text: "Go to docs", url: docsURL)
                ]
            ])
        )
        
        return telegramClient.sendMessage(
            chatID: monitor.telegramDialogueID,
            text: message,
            replyMarkup: replyMarkup
        )
    }
}

struct CollateralizationFetchJob: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        CollateralizationAlertsOperation(
            telegramClient: context.application.telegramClient,
            keepClient: context.application.keepClient,
            web3: Web3(provider: context.application.web3Provider),
            db: context.application.db,
            eventLoop: context.eventLoop
        ).run()
    }
}

private extension TimeInterval {
    var formatted: String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
