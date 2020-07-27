//
//  AlertMonitor.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor
import Fluent

final class AlertMonitor: Model {
    static let schema = "alert_monitors"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "operator_address")
    var operatorAddress: String

    @Field(key: "telegram_dialogue_id")
    var telegramDialogueID: Int
    
    @Field(key: "eth_threshold")
    var ethThreshold: UInt
    
    init() { }

    init(id: UUID? = nil, telegramDialogueID: Int, operatorAddress: String, ethThreshold: UInt) {
        self.id = id
        self.telegramDialogueID = telegramDialogueID
        self.operatorAddress = operatorAddress
        self.ethThreshold = ethThreshold
    }
}
