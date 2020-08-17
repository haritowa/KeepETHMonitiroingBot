//
//  KeepClient+FetchUnbondedBatch.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor
import Web3

typealias KeepUnbondedTokensFetchBatchResult = [EthereumAddress: BigUInt]

extension KeepClientProtocol {
    private func unbondedValueWithAddress(for operatorAddress: EthereumAddress) -> EventLoopFuture<(EthereumAddress, BigUInt)> {
        unbondedValue(operatorAddress: operatorAddress)
            .map { (operatorAddress, $0) }
    }
    
    func unbondedValues(for operators: [EthereumAddress]) -> EventLoopFuture<KeepUnbondedTokensFetchBatchResult> {
        EventLoopFuture.reduce(
            into: KeepUnbondedTokensFetchBatchResult(),
            operators.map(unbondedValueWithAddress),
            on: eventLoop
        ) { (acc, value) in
            acc[value.0] = value.1
        }
    }
}
