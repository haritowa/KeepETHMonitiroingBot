//
//  File.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor

import Web3
import Web3ContractABI

struct SolidityInvocationUnknownError: Error { }

struct SolidityInvocationParamExtractionError: Error {
    let key: String
    let value: Any?
}

extension SolidityInvocation {
    func call(eventLoop: EventLoop) -> EventLoopFuture<[String: Any]> {
        let promise = eventLoop.makePromise(of: [String: Any].self)
        
        self.call { (data, error) in
            if let data = data {
                promise.succeed(data)
            } else if let error = error {
                promise.fail(error)
            } else {
                promise.fail(SolidityInvocationUnknownError())
            }
        }
        
        return promise.futureResult
    }
    
    private func getDefaultOutputKey(for proposedKey: String?) -> String {
        proposedKey ?? method.outputs?.first?.name ?? ""
    }
    
    func callAndExtract<T>(eventLoop: EventLoop, valueKey: String? = nil) -> EventLoopFuture<T> {
        let key = getDefaultOutputKey(for: valueKey)
        
        return call(eventLoop: eventLoop).flatMapThrowing { data in
            guard let value = data[key] as? T else {
                throw SolidityInvocationParamExtractionError(
                    key: key,
                    value: data[key]
                )
            }
            
            return value
        }
    }
}
