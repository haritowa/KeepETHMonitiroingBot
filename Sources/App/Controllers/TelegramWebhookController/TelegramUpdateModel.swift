//
//  TelegramUpdateModel.swift
//  
//
//  Created by Anton Kharchenko on 7/28/20.
//

import Foundation
import Vapor

enum TelegramChatType: String, Content {
    case group, supergroup, channel
    case privateDialogue = "private"
}

struct TelegramUserModel: Content {
    let id: Int
}

struct TelegramChatModel: Content {
    let id: Int
    let type: TelegramChatType
}

struct TelegramMessageEntityModel: Content {
    let type: String
    let offset: Int
    let length: Int
    
    var isBotCommand: Bool { type == "bot_command" }
}

struct TelegramMessageModel: Content {
    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case from, chat, text, entities
    }
    
    let messageID: Int
    let from: TelegramUserModel?
    let chat: TelegramChatModel
    let text: String?
    let entities: [TelegramMessageEntityModel]?
}

struct TelegramUpdateModel: Content {
    enum CodingKeys: String, CodingKey {
        case updateID = "update_id"
        case message
    }
    
    let updateID: Int
    let message: TelegramMessageModel?
}
