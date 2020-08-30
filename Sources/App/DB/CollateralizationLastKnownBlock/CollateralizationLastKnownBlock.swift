//
//  CollateralizationLastKnownBlock.swift
//  
//
//  Created by Anton Kharchenko on 8/30/20.
//

import Foundation
import Vapor
import Fluent

final class CollateralizationLastKnownBlock: Model {
    static let schema = "collateralization_last_known_block"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "block_number")
    var blockNumber: String
    
    @Field(key: "date")
    var date: Date
    
    init() { }

    init(id: UUID? = nil, blockNumber: String, date: Date) {
        self.id = id
        self.blockNumber = blockNumber
        self.date = date
    }
}
