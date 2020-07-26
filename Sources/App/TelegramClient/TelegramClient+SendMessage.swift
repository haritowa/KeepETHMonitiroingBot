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
    }
    
    let chatID: Int
    let text: String
    let replyMessageID: Int?
}

extension TelegramClientProtocol {
    func sendMessage(chatID: Int, replyMessageID: Int?, text: String) -> EventLoopFuture<Void> {
        let uri = getURI(for: "sendMessage")
        
        let content = TelegramSendMessageRequestModel(
            chatID: chatID,
            text: text,
            replyMessageID: replyMessageID
        )
        
        return client.post(uri, beforeSend: { try $0.content.encode(content) })
            .flatMapThrowing(TelegramResponseParser<Void>.parseResponse)
    }
    
    func sendMessage(chatID: Int, text: String) -> EventLoopFuture<Void> {
        sendMessage(chatID: chatID, replyMessageID: nil, text: text)
    }
}
