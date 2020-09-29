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

enum DepostCollateralizationState {
    case normal
    case undercollateralized
    case severelyUndercollateralized
}

protocol KeepClientProtocol {
    var eventLoop: EventLoop { get }
    
    func unbondedValue(operatorAddress: EthereumAddress) -> EventLoopFuture<BigUInt>
    func hasTBTCAuthorization(operatorAddress: EthereumAddress) -> EventLoopFuture<KeepTBTCAuthResult>
    func depositState(depositAddress: EthereumAddress) -> EventLoopFuture<DepostCollateralizationState>
    
    func operators(for depositAddress: EthereumAddress) -> EventLoopFuture<[EthereumAddress]>
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
        web3.eth.Contract(type: KeepBondingContract.self, address: KeepBondingContract.contractAddress)
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
    
    func depositState(depositAddress: EthereumAddress) -> EventLoopFuture<DepostCollateralizationState> {
        let current = collateralizationPercentage(for: depositAddress).map(UInt.init)
        let firstGrade = undercollateralizedThresholdPercent(for: depositAddress).map(UInt.init)
        let secondGrade = severelyUndercollateralizedThresholdPercent(for: depositAddress).map(UInt.init)
        
        return EventLoopFuture.whenAllSucceed([current, firstGrade, secondGrade], on: eventLoop).map { items in
            let currentValue = items[0]
            let firstGradeValue = items[1]
            let secondGradeValue = items[2]
            
            if currentValue < secondGradeValue {
                return DepostCollateralizationState.severelyUndercollateralized
            } else if currentValue < firstGradeValue {
                return DepostCollateralizationState.undercollateralized
            } else {
                return DepostCollateralizationState.normal
            }
        }
    }
    
    private func getTBTCSoritonPool(for operatorAddress: EthereumAddress) -> EventLoopFuture<EthereumAddress> {
        web3.eth.Contract(type: BondedECDSAKeepFactoryContract.self, address: BondedECDSAKeepFactoryContract.contractAddress)
            .getSortitionPool(applicationAddress: TBTCSystemContract.contractAddress)
            .callAndExtract(eventLoop: eventLoop)
    }
    
    private func hasContractAuthorization(for operatorAddress: EthereumAddress, sortitionPool: EthereumAddress) -> EventLoopFuture<Bool> {
        web3.eth.Contract(type: KeepBondingContract.self, address: KeepBondingContract.contractAddress)
            .hasSecondaryAuthorization(operatorAddress: operatorAddress, sortitionPool: sortitionPool)
            .callAndExtract(eventLoop: eventLoop)
    }
    
    private func hasTBTCAuthorization(for operatorAddress: EthereumAddress, sortitionPool: EthereumAddress) -> EventLoopFuture<KeepTBTCAuthResult> {
        hasContractAuthorization(for: operatorAddress, sortitionPool: sortitionPool)
            .map { $0 ? KeepTBTCAuthResult.granted : KeepTBTCAuthResult.notAuthorized }
            .flatMapErrorThrowing { _ in KeepTBTCAuthResult.uknownError }
    }
    
    func operators(for depositAddress: EthereumAddress) -> EventLoopFuture<[EthereumAddress]> {
        let deposit = self.deposit(for: depositAddress)
        
        let keepAddress: EventLoopFuture<EthereumAddress> = deposit.keepAddress.callAndExtract(eventLoop: eventLoop)
        
        return keepAddress
            .map { BondedECDSAKeepContract(address: $0, eth: self.web3.eth) }
            .flatMap { contract -> EventLoopFuture<[EthereumAddress]> in contract.members.callAndExtract(eventLoop: self.eventLoop) }
    }
    
    // MARK: - Depost Collateralization
    private func deposit(for depositAddress: EthereumAddress) -> DepositContract {
        DepositContract(address: depositAddress, eth: web3.eth)
    }
    
    private func collateralizationPercentage(for depositAddress: EthereumAddress) -> EventLoopFuture<BigUInt> {
        deposit(for: depositAddress)
            .collateralizationPercentage
            .callAndExtract(eventLoop: eventLoop)
    }
    
    private func undercollateralizedThresholdPercent(for depositAddress: EthereumAddress) -> EventLoopFuture<UInt16> {
        deposit(for: depositAddress)
            .undercollateralizedThresholdPercent
            .callAndExtract(eventLoop: eventLoop)
    }
    
    private func severelyUndercollateralizedThresholdPercent(for depositAddress: EthereumAddress) -> EventLoopFuture<UInt16> {
        deposit(for: depositAddress)
            .severelyUndercollateralizedThresholdPercent
            .callAndExtract(eventLoop: eventLoop)
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
