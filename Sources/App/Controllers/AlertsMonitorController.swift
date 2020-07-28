//
//  AlertsMonitorController.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor

import Fluent

class AlertsMonitorController {
    static func sendCurrentMonitors(request: Request, for telegramID: Int) -> EventLoopFuture<Void> {
        GetMyAlertsRoutine.sendCurrentMonitors(for: telegramID, request: request)
    }
    
    static func addMonitor(request: Request, for telegramID: Int, address: String, ethThreshold: UInt) -> EventLoopFuture<Void> {
        AddMonitorRoutine.addMonitor(request: request, for: telegramID, address: address, ethThreshold: ethThreshold)
    }
}
