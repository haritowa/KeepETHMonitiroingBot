//
//  AlertsMonitorController.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor

import Fluent

private extension EventLoopFuture {
    func asTelegramSuccess() -> EventLoopFuture<String> {
        map { _ in "True" }
    }
}

class AlertsMonitorController {
    static func sendCurrentMonitors(request: Request, for telegramID: Int) -> EventLoopFuture<String> {
        GetMyAlertsRoutine.sendCurrentMonitors(for: telegramID, request: request)
            .asTelegramSuccess()
    }
    
    static func addMonitor(request: Request, for telegramID: Int, address: String, ethThreshold: UInt) -> EventLoopFuture<String> {
        AddMonitorRoutine.addMonitor(request: request, for: telegramID, address: address, ethThreshold: ethThreshold)
            .asTelegramSuccess()
    }
}
