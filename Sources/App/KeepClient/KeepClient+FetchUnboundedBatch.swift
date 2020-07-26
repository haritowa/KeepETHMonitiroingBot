//
//  KeepClient+FetchUnboundedBatch.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor
import Web3

typealias KeepUnboundedTokensFetchBatchResult = [EthereumAddress: BigUInt]

extension KeepClientProtocol {
    private func unboundedValueWithAddress(for operatorAddress: EthereumAddress) -> EventLoopFuture<(EthereumAddress, BigUInt)> {
        unbondedValue(operatorAddress: operatorAddress)
            .map { (operatorAddress, $0) }
    }
    
    func unbondedValues(for operators: [EthereumAddress]) -> EventLoopFuture<KeepUnboundedTokensFetchBatchResult> {
        EventLoopFuture.reduce(
            into: KeepUnboundedTokensFetchBatchResult(),
            operators.map(unboundedValueWithAddress),
            on: eventLoop
        ) { (acc, value) in
            acc[value.0] = value.1
        }
    }
}
