//
//  KeepClient.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor
import Web3

protocol KeepClientProtocol {
    var eventLoop: EventLoop { get }
    
    func unbondedValue(operatorAddress: EthereumAddress) -> EventLoopFuture<BigUInt>
}

class KeepClient: KeepClientProtocol {
    private let web3: Web3
    private let provider: Web3VaporProvider
    
    var eventLoop: EventLoop { provider.client.eventLoop }
    
    init(provider: Web3VaporProvider) {
        self.provider = provider
        self.web3 = Web3(provider: provider)
    }
    
    func unbondedValue(operatorAddress: EthereumAddress) -> EventLoopFuture<BigUInt> {
        web3.eth.Contract(type: KeepBoundingContract.self, address: KeepBoundingContract.testNetAddress)
            .unbondedValue(operatorAddress: operatorAddress)
            .callAndExtract(eventLoop: eventLoop)
    }
}

extension Request {
    var keepClient: KeepClientProtocol {
        KeepClient(provider: web3Provider)
    }
}
