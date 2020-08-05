//
//  TelegramWebhookController.swift
//  
//
//  Created by Anton Kharchenko on 7/28/20.
//

import Foundation
import Vapor
import Web3

private protocol TelegramWebhookCommand {
    var telegramID: Int { get }
}

private struct SetupMonitorTelegramWebhookCommand: TelegramWebhookCommand {
    let telegramID: Int
    let address: String
    let ethThreshold: UInt
}

private struct RemoveMonitorTelegramWebhookCommand: TelegramWebhookCommand {
    let telegramID: Int
    let address: String
}

private struct MyMonitorsTelegramWebhookCommand: TelegramWebhookCommand {
    let telegramID: Int
}

private enum TelegramWebhookCommandName: String {
    case setupMonitor = "/setup"
    case myMonitors = "/list"
    case remove = "/remove"
    case start = "/start"
}

private struct TelegramWebhookCommandParsingError: Error {
    let errorMessages: [TelegramSendMessageRequestModel]
}

struct TelegramWebhookController {
    static func handle(request: Request) -> EventLoopFuture<String> {
        TelegramUpdateModel.decodeRequest(request)
            .flatMapThrowing(getCommand)
            .flatMap(Self.runCommand(with: request))
            .flatMapError(Self.postError(with: request))
            .map { _ in "True" }
        
    }
    
    // MARK: - Errors generation
    private static func createEmptyError() -> TelegramWebhookCommandParsingError {
        TelegramWebhookCommandParsingError(errorMessages: [])
    }
    
    private static func createError(with singleMessage: String, chatID: Int) -> TelegramWebhookCommandParsingError {
        return TelegramWebhookCommandParsingError(
            errorMessages: [
                TelegramSendMessageRequestModel(chatID: chatID, text: singleMessage, replyMessageID: nil, replyMarkup: nil)
            ]
        )
    }
    
    // MARK: - Command parsing
    private static func getCommandName(message: String, chatID: Int, entity: TelegramMessageEntityModel) throws -> TelegramWebhookCommandName {
        guard let substring = message.substr(entity.offset, entity.length) else {
            throw createEmptyError()
        }
        
        guard let commandName = TelegramWebhookCommandName(rawValue: substring) else {
            throw createError(with: "Unknown command: \(substring)", chatID: chatID)
        }
        
        return commandName
    }
    
    private static func commandUsageHelp(for commandName: TelegramWebhookCommandName, chatID: Int) -> TelegramSendMessageRequestModel {
        let result: String
        
        switch commandName {
        case .setupMonitor:
            result = "Use this format:\n\(commandName.rawValue) <*Operator Address*>(hex) <*Alert Threshold*>(integer)"
        case .remove:
            result = "Use this format:\n\(commandName.rawValue) <*Operator Address*>(hex)"
        case .myMonitors:
            result = "Usage: \(commandName.rawValue)"
        case .start:
            result = "You can add your monitors with \(TelegramWebhookCommandName.setupMonitor.rawValue) command"
        }
        
        return TelegramSendMessageRequestModel(chatID: chatID, text: result, replyMessageID: nil, replyMarkup: nil)
    }
    
    private static func commandUsageHelpError(for commandName: TelegramWebhookCommandName, chatID: Int) -> TelegramWebhookCommandParsingError {
        TelegramWebhookCommandParsingError(errorMessages: [commandUsageHelp(for: commandName, chatID: chatID)])
    }
    
    private static func sendUsageError(
        commandName: TelegramWebhookCommandName,
        with additionalError: String,
        chatID: Int
    ) -> Error {
        let error = TelegramSendMessageRequestModel(chatID: chatID, text: additionalError)
        return TelegramWebhookCommandParsingError(errorMessages: [
            commandUsageHelp(for: commandName, chatID: chatID),
            error
        ])
    }
    
    private static func parseSetupMonitorCommand(
        entity: TelegramMessageEntityModel,
        message: String,
        chatID: Int
    ) throws -> TelegramWebhookCommand {
        let messageData = message.dropFirst(entity.offset + entity.length + 1)
        
        let components = messageData.components(separatedBy: .whitespaces)
        guard components.count == 2 else {
            throw commandUsageHelpError(for: .setupMonitor, chatID: chatID)
        }
        
        let ethAddressComponent = components[0]
        
        guard (try? EthereumAddress(hex: ethAddressComponent, eip55: false)) != nil else {
            throw sendUsageError(commandName: .setupMonitor, with: "Etherum adress is invalid", chatID: chatID)
        }
        
        guard let thresholdComponent = UInt.init(components[1]) else {
            throw sendUsageError(commandName: .setupMonitor, with: "Threshold value is invalid", chatID: chatID)
        }
        
        guard thresholdComponent > 0 else {
            throw sendUsageError(commandName: .setupMonitor, with: "Threshold value must be greater than zero", chatID: chatID)
        }
        
        return SetupMonitorTelegramWebhookCommand(telegramID: chatID, address: ethAddressComponent, ethThreshold: thresholdComponent)
    }
    
    private static func parseRemoveMonitorCommand(
        entity: TelegramMessageEntityModel,
        message: String,
        chatID: Int
    ) throws -> TelegramWebhookCommand {
        let messageData = message.dropFirst(entity.offset + entity.length + 1)
        
        let components = messageData.components(separatedBy: .whitespaces)
        guard components.count == 1 else {
            throw commandUsageHelpError(for: .remove, chatID: chatID)
        }
        
        let ethAddressComponent = components[0]
        
        guard ethAddressComponent.hasPrefix("0x") else {
            throw sendUsageError(commandName: .remove, with: "Etherum adress is invalid", chatID: chatID)
        }
        
        guard ethAddressComponent.count >= 4 else {
            throw sendUsageError(commandName: .remove, with: "Enter at least 4 chars from your address", chatID: chatID)
        }
        
        return RemoveMonitorTelegramWebhookCommand(telegramID: chatID, address: ethAddressComponent)
    }
    
    private static func parseCommand(
        with name: TelegramWebhookCommandName,
        entity: TelegramMessageEntityModel,
        message: String,
        chatID: Int
    ) throws -> TelegramWebhookCommand {
        switch name {
        case .start:
            throw commandUsageHelpError(for: .start, chatID: chatID)
        case .myMonitors:
            return MyMonitorsTelegramWebhookCommand(telegramID: chatID)
        case .setupMonitor:
            return try parseSetupMonitorCommand(entity: entity, message: message, chatID: chatID)
        case .remove:
            return try parseRemoveMonitorCommand(entity: entity, message: message, chatID: chatID)
        }
    }
    
    private static func getCommand(from updateModel: TelegramUpdateModel) throws -> TelegramWebhookCommand {
        guard let message = updateModel.message, message.from != nil, let text = message.text else { throw createEmptyError() }
        guard message.chat.type == .privateDialogue else { throw createError(with: "Alerts are available only in private channels", chatID: message.chat.id) }
        
        let entities = message.entities?.filter { $0.isBotCommand } ?? []
        let commandRef: TelegramMessageEntityModel
        
        switch entities.count {
        case 0: throw createEmptyError()
        case 1: commandRef = entities[0]
        default: throw createError(with: "Message can contain only one command", chatID: message.chat.id)
        }
        
        let commandName = try getCommandName(message: text, chatID: message.chat.id, entity: commandRef)
        return try parseCommand(with: commandName, entity: commandRef, message: text, chatID: message.chat.id)
    }
    
    // MARK: - Command execution
    private static func runCommand(with request: Request) -> (TelegramWebhookCommand) -> EventLoopFuture<Void> {
        return { command in
            if let listCommand = command as? MyMonitorsTelegramWebhookCommand {
                return AlertsMonitorController.sendCurrentMonitors(
                    request: request,
                    for: listCommand.telegramID
                )
            } else if let setupCommand = command as? SetupMonitorTelegramWebhookCommand {
                return AlertsMonitorController.addMonitor(
                    request: request,
                    for: setupCommand.telegramID,
                    address: setupCommand.address,
                    ethThreshold: setupCommand.ethThreshold
                )
            } else if let removeCommand = command as? RemoveMonitorTelegramWebhookCommand {
                return DeleteMonitorRoutine.perform(
                    with: request,
                    telegramID: removeCommand.telegramID,
                    addressQuery: removeCommand.address
                )
            } else {
                return request.eventLoop.makeFailedFuture(createError(with: "Unknown error", chatID: command.telegramID))
            }
        }
    }
    
    // MARK: - Error posting
    private static func postError(with request: Request) -> (Error) -> EventLoopFuture<Void> {
        return { error in
            guard let commandParsingError = error as? TelegramWebhookCommandParsingError else {
                return request.eventLoop.makeFailedFuture(error)
            }
            
            let work = commandParsingError.errorMessages.map(request.telegramClient.sendMessage)
            return EventLoopFuture<Void>.whenAllComplete(work, on: request.eventLoop)
                .map { _ in () }
        }
    }
}
