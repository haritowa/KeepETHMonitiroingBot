//
//  TelegramClient+SendMessage.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation
import Vapor

enum TelegramMessageParseMode: String, Content {
    case MarkdownV2
    case Markdown
}

struct TelegramSendMessageRequestModel: Content {
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case text
        case replyMessageID = "reply_to_message_id"
        case replyMarkup = "reply_markup"
        case parseMode = "parse_mode"
        case disableWebPagePreview = "disable_web_page_preview"
    }
    
    let chatID: Int
    let text: String
    let replyMessageID: Int?
    let parseMode: TelegramMessageParseMode?
    let disableWebPagePreview: Bool?
    
    let replyMarkup: TelegramClientReplyMarkup?
    
    init(
        chatID: Int,
        text: String,
        replyMessageID: Int? = nil,
        parseMode: TelegramMessageParseMode? = .Markdown,
        disableWebPagePreview: Bool? = true,
        replyMarkup: TelegramClientReplyMarkup? = nil
    ) {
        self.chatID = chatID
        self.text = text
        self.replyMessageID = replyMessageID
        self.parseMode = parseMode
        self.disableWebPagePreview = disableWebPagePreview
        self.replyMarkup = replyMarkup
    }
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
        
        if let parseMode = parseMode {
            try container.encode(parseMode, forKey: .parseMode)
        }
        
        if let disableWebPagePreview = disableWebPagePreview {
            try container.encode(disableWebPagePreview, forKey: .disableWebPagePreview)
        }
        
        switch replyMarkup {
        case .replyKeyboard(let keyboard): try container.encode(keyboard, forKey: .replyMarkup)
        case .forceReply(let reply): try container.encode(reply, forKey: .replyMarkup)
        case .none: break
        }
    }
}

extension TelegramClientProtocol {
    func sendMessage(messageModel: TelegramSendMessageRequestModel) -> EventLoopFuture<Void> {
        let uri = getURI(for: "sendMessage")
        let content = messageModel
        
        return client.post(uri, beforeSend: { try $0.content.encode(content) })
            .flatMapThrowing(TelegramResponseParser<Void>.parseResponse)
    }
    
    func sendMessage(chatID: Int, replyMessageID: Int?, text: String, replyMarkup: TelegramClientReplyMarkup?) -> EventLoopFuture<Void> {
        sendMessage(messageModel: TelegramSendMessageRequestModel(chatID: chatID, text: text, replyMessageID: replyMessageID, replyMarkup: replyMarkup))
    }
    
    func sendMessage(chatID: Int, text: String, replyMessageID: Int? = nil, replyMarkup: TelegramClientReplyMarkup? = nil) -> EventLoopFuture<Void> {
        sendMessage(chatID: chatID, replyMessageID: nil, text: text, replyMarkup: replyMarkup)
    }
}
