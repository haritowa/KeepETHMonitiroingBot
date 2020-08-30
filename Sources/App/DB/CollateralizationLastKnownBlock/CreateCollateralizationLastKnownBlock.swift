//
//  CreateCollateralizationLastKnownBlock.swift
//  
//
//  Created by Anton Kharchenko on 8/30/20.
//

import Foundation
import Fluent

struct CreateCollateralizationLastKnownBlock: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CollateralizationLastKnownBlock.schema)
            .id()
            .field("block_number", .string, .required)
            .field("date", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CollateralizationLastKnownBlock.schema).delete()
    }
}

