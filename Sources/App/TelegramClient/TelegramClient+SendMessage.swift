//
//  TelegramClient+SendMessage.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation
import Vapor

private struct TelegramSendMessageRequestModel: Content {
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case text
        case replyMessageID = "reply_to_message_id"
        case replyMarkup = "reply_markup"
    }
    
    let chatID: Int
    let text: String
    let replyMessageID: Int?
    
    let replyMarkup: TelegramClientReplyMarkup?
}

extension TelegramSendMessageRequestModel {
    init(from decoder: Decoder) throws {
        fatalError()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(chatID, forKey: .chatID)
        try container.encode(text, forKey: .text)
        
        if let replyMessageID = replyMessageID {
            try container.encode(replyMessageID, forKey: .replyMessageID)
        }
        
        switch replyMarkup {
        case .replyKeyboard(let keyboard): try container.encode(keyboard, forKey: .replyMarkup)
        case .forceReply(let reply): try container.encode(reply, forKey: .replyMarkup)
        case .none: break
        }
    }
}

extension TelegramClientProtocol {
    func sendMessage(chatID: Int, replyMessageID: Int?, text: String, replyMarkup: TelegramClientReplyMarkup?) -> EventLoopFuture<Void> {
        let uri = getURI(for: "sendMessage")
        
        let content = TelegramSendMessageRequestModel(
            chatID: chatID,
            text: text,
            replyMessageID: replyMessageID,
            replyMarkup: replyMarkup
        )
        
        return client.post(uri, beforeSend: { try $0.content.encode(content) })
            .flatMapThrowing(TelegramResponseParser<Void>.parseResponse)
    }
    
    func sendMessage(chatID: Int, text: String, replyMessageID: Int? = nil, replyMarkup: TelegramClientReplyMarkup? = nil) -> EventLoopFuture<Void> {
        sendMessage(chatID: chatID, replyMessageID: nil, text: text, replyMarkup: replyMarkup)
    }
}
