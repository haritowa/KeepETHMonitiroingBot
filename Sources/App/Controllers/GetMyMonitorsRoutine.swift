//
//  GetMyMonitorsRoutine.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor

import Fluent

struct GetMyAlertsRoutine {
    private static func getAlertMonitors(database: Database, for telegramID: Int) -> EventLoopFuture<[AlertMonitor]> {
        AlertMonitor
            .query(on: database)
            .filter(\.$telegramDialogueID == telegramID)
            .all()
    }
    
    private static func emptyMonitorsSummary() -> String {
        return "You don't have any monitors"
    }
    
    private static func createSummaryMessage(for alerts: [AlertMonitor]) -> String {
        guard !alerts.isEmpty else { return emptyMonitorsSummary() }
        
        let monitorDescriptions = alerts.map { monitor in
            "\(createEtherscanLink(for: monitor.operatorAddress)) : *\(monitor.ethThreshold)* ETH"
        }.joined(separator: "\n")
        
        return """
        Your active monitors are:
        
        \(monitorDescriptions)
        """
    }
    
    static func sendCurrentMonitors(for telegramID: Int, request: Request) -> EventLoopFuture<Void> {
        getAlertMonitors(database: request.db, for: telegramID)
            .map(createSummaryMessage)
            .flatMap { request.telegramClient.sendMessage(chatID: telegramID, text: $0) }
    }
}
