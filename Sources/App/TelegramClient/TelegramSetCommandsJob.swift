//
//  TelegramSetCommandsJob.swift
//  
//
//  Created by Anton Kharchenko on 7/29/20.
//

import Foundation

import Vapor
import Queues

import Fluent
import Web3

struct SetTelegramCommandsJob: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        context.application
            .telegramClient
            .setCommands(list: Self.generateCommands())
    }
    
    private static func generateCommands() -> TelegramBotCommandsList {
        TelegramBotCommandsList(
            commands: [
                TelegramBotCommand(command: "setup", description: "Create or update monitor"),
                TelegramBotCommand(command: "list", description: "Show all active monitors"),
                TelegramBotCommand(command: "remove", description: "Remove monitor. You can use specify only few chars from operator address")
            ]
        )
    }
}
