//
//  TelegramClient.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation
import Vapor

class TelegramClient: TelegramClientProtocol {
    let client: Client
    let botRootURL: URL
    
    init(apiKey: String, client: Client) {
        self.client = client
        self.botRootURL = Self.createBotRootURI(for: apiKey)
    }
    
    func getURI(for method: String) -> URI {
        URI(string: botRootURL.appendingPathComponent(method).absoluteString)
    }
    
    private static func createBotRootURI(for apiKey: String) -> URL {
        URL(string: "https://api.telegram.org/bot\(apiKey)")!
    }
}

extension Request {
    var telegramBotAPIKey: String { return "1372997939:AAHdcWh4ouHBAgNETLuIpenRMqDEoepozeM" }
    
    var telegramClient: TelegramClientProtocol { TelegramClient(apiKey: telegramBotAPIKey, client: client) }
}

extension Application {
    var telegramBotAPIKey: String { return "1372997939:AAHdcWh4ouHBAgNETLuIpenRMqDEoepozeM" }
    
    var telegramClient: TelegramClientProtocol { TelegramClient(apiKey: telegramBotAPIKey, client: client) }
}
