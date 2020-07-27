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
    static func sendCurrentMonitors(for telegramID: Int, request: Request) -> EventLoopFuture<String> {
        GetMyAlertsRoutine.sendCurrentMonitors(for: telegramID, request: request)
            .map { _ in "True" }
    }
}
