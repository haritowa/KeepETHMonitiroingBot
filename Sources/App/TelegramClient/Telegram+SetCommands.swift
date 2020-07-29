//
//  Telegram+SetCommands.swift
//  
//
//  Created by Anton Kharchenko on 7/29/20.
//

import Foundation
import Vapor

struct TelegramBotCommand: Content {
    let command: String
    let description: String
}

struct TelegramBotCommandsList: Content {
    let commands: [TelegramBotCommand]
}

extension TelegramClientProtocol {
    func setCommands(list: TelegramBotCommandsList) -> EventLoopFuture<Void> {
        let uri = getURI(for: "setMyCommands")
        let content = list
        
        return client.post(uri, beforeSend: { try $0.content.encode(content) })
            .flatMapThrowing(TelegramResponseParser<Void>.parseResponse)
    }
}
