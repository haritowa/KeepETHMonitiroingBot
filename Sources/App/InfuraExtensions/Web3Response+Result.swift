//
//  Web3Response+Result.swift
//  
//
//  Created by Anton Kharchenko on 8/30/20.
//

import Foundation

import Vapor
import Web3

extension Web3Response {
    func asResult() -> Swift.Result<Result, Swift.Error> {
        if let result = result {
            return .success(result)
        } else if let error = error {
            return .failure(error)
        } else {
            return .failure(Error.requestFailed(nil))
        }
    }
}
