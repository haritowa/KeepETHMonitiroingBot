//
//  TelegramClientReplyKeyboard.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation
import Vapor

enum TelegramClientReplyMarkup {
    case replyKeyboard(TelegramClientReplyKeyboard)
    case forceReply(TelegramClientForceReply)
}

struct TelegramClientKeyboardButton: Encodable, ExpressibleByStringLiteral {
    let text: String
    
    init(stringLiteral value: StringLiteralType) {
        self.text = value
    }
}

struct TelegramClientReplyKeyboard: Encodable {
    enum CodingKeys: String, CodingKey {
        case keyboard
        case isOneTime = "one_time_keyboard"
    }
    
    let keyboard: [[TelegramClientKeyboardButton]]
    let isOneTime: Bool?
}

struct TelegramClientForceReply: Encodable {
    enum CodingKeys: String, CodingKey {
        case forceReply = "force_reply"
    }
    
    let forceReply: Bool
}
