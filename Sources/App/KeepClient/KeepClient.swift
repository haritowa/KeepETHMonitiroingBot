//
//  KeepClient.swift
//  
//
//  Created by Anton Kharchenko on 7/27/20.
//

import Foundation
import Vapor
import Web3

enum KeepTBTCAuthResult {
    case granted
    case cantGetSoritonPool
    case notAuthorized
    case uknownError
}

protocol KeepClientProtocol {
    var eventLoop: EventLoop { get }
    
    func unbondedValue(operatorAddress: EthereumAddress) -> EventLoopFuture<BigUInt>
    func hasTBTCAuthorization(operatorAddress: EthereumAddress) -> EventLoopFuture<KeepTBTCAuthResult>
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
        web3.eth.Contract(type: KeepBondingContract.self, address: KeepBondingContract.testNetAddress)
            .unbondedValue(operatorAddress: operatorAddress)
            .callAndExtract(eventLoop: eventLoop)
    }
    
    func hasTBTCAuthorization(operatorAddress: EthereumAddress) -> EventLoopFuture<KeepTBTCAuthResult> {
        getTBTCSoritonPool(for: operatorAddress).flatMapAlways { fetchSortitionPoolResult in
            switch fetchSortitionPoolResult {
            case .failure: return self.eventLoop.future(KeepTBTCAuthResult.cantGetSoritonPool)
            case .success(let sortitionPool): return self.hasTBTCAuthorization(for: operatorAddress, sortitionPool: sortitionPool)
            }
        }
    }
    
    private func getTBTCSoritonPool(for operatorAddress: EthereumAddress) -> EventLoopFuture<EthereumAddress> {
        web3.eth.Contract(type: BondedECDSAKeepFactoryContract.self, address: BondedECDSAKeepFactoryContract.testNetAddress)
            .getSortitionPool(applicationAddress: TBTCSystemContract.testNetAddress)
            .callAndExtract(eventLoop: eventLoop)
    }
    
    private func hasContractAuthorization(for operatorAddress: EthereumAddress, sortitionPool: EthereumAddress) -> EventLoopFuture<Bool> {
        web3.eth.Contract(type: KeepBondingContract.self, address: KeepBondingContract.testNetAddress)
            .hasSecondaryAuthorization(operatorAddress: operatorAddress, sortitionPool: sortitionPool)
            .callAndExtract(eventLoop: eventLoop)
    }
    
    private func hasTBTCAuthorization(for operatorAddress: EthereumAddress, sortitionPool: EthereumAddress) -> EventLoopFuture<KeepTBTCAuthResult> {
        hasContractAuthorization(for: operatorAddress, sortitionPool: sortitionPool)
            .map { $0 ? KeepTBTCAuthResult.granted : KeepTBTCAuthResult.notAuthorized }
            .flatMapErrorThrowing { _ in KeepTBTCAuthResult.uknownError }
    }
}

extension Request {
    var keepClient: KeepClientProtocol {
        KeepClient(provider: web3Provider)
    }
}

extension Application {
    var keepClient: KeepClientProtocol {
        KeepClient(provider: web3Provider)
    }
}
