//
//  TelegramClientResponse.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation
import Vapor

struct TelegramResponseError: Content, Error {
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case description
    }
    
    let errorCode: Int
    let description: String
}

struct TelegramResponseContainer<T: Content>: Content {
    let result: T
}

struct TelegramResponseParser<C> { }

extension TelegramResponseParser where C: Content {
    static func parseResponse(from response: ClientResponse) throws -> C {
        switch response.status.code {
        case 100..<400:
            return try response.content.decode(TelegramResponseContainer<C>.self).result
        default:
            throw try response.content.decode(TelegramResponseError.self)
        }
    }
}

extension TelegramResponseParser where C == Void {
    static func parseResponse(from response: ClientResponse) throws -> C {
        switch response.status.code {
        case 100..<400:
            return
        default:
            throw try response.content.decode(TelegramResponseError.self)
        }
    }
}
