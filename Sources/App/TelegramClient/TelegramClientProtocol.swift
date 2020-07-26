//
//  TelegramClientProtocol.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation
import Vapor

protocol TelegramClientProtocol {
    var client: Client { get }
    func getURI(for method: String) -> URI
    
    func sendMessage(chatID: Int, replyMessageID: Int?, text: String) -> EventLoopFuture<Void>
}
