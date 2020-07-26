//
//  CreateAlertMonitor.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Fluent

struct CreateAlertMonitor: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AlertMonitor.schema)
            .id()
            .field("operator_address", .string, .required)
            .field("telegramDialogueID", .int, .required)
            .field("eth_threshold", .int, .required)
            .unique(on: "operator_address")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AlertMonitor.schema).delete()
    }
}
