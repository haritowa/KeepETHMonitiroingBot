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
        let fetchResult = CollateralizationFetchRoutine(
            fromBlock: .earliest,
            eventLoop: eventLoop,
            web3: web3,
            keepClient: keepClient
        ).perform()
        
        return fetchResult.flatMap(run)
    }
    
    private func run(fetchResult: CollateralizationPollingFetchResult) -> EventLoopFuture<Void> {
        getAllMatchingAllerts(for: Set(fetchResult.alerts.keys))
            .flatMap { self.sendAlert(fetchResult: fetchResult, monitors: $0) }
    }
    
    private func getAllMatchingAllerts(
        for operators: Set<String>
    ) -> EventLoopFuture<[AlertMonitor]> {
        AlertMonitor
            .query(on: db)
            .filter(\.$operatorAddress ~~ operators)
            .field(\.$telegramDialogueID)
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
        
        let formattedRemainigTime = alert.date.timeIntervalSinceNow.format(using: [.hour, .minute]).map { time in
            "You have \(time) until the auction starts"
        } ?? ""
        
        return "⚠️ Your operator \(createEtherscanLink(for: operatorAddress)) have undercollateralized deposit \(createEtherscanLink(for: depositAddress)). \(formattedRemainigTime)"
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

extension TimeInterval {
    func format(using units: NSCalendar.Unit) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: self)
    }
}

