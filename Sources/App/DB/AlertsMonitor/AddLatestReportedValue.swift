//
//  AddLatestReportedValue.swift
//  
//
//  Created by Anton Kharchenko on 7/29/20.
//

import Foundation
import Fluent

struct AddLatestReportedValue: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AlertMonitor.schema)
            .field("latest_reported_value", .uint)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AlertMonitor.schema)
            .deleteField("latest_reported_value")
            .update()
    }
}

