//
//  KeepBondingContract.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation

import Web3
import Web3ContractABI

class KeepBondingContract: GenericERC20Contract {
    static let testNetAddress = EthereumAddress(hexString: "0x60535A59B4e71F908f3fEB0116F450703FB35eD8")!
    
    func unbondedValue(operatorAddress: EthereumAddress) -> SolidityInvocation {
        let inputs = [SolidityFunctionParameter(name: "address", type: .address)]
        let outputs = [SolidityFunctionParameter(name: "_unbondedValue", type: .uint256)]
        let method = SolidityConstantFunction(name: "unbondedValue", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke(operatorAddress)
    }
    
    func availableUnbondedValue(
        operatorAddress: EthereumAddress,
        bondCreator: EthereumAddress,
        authorizedSortitionPool: EthereumAddress
    ) -> SolidityInvocation {
        let inputs = [
            SolidityFunctionParameter(name: "operator", type: .address),
            SolidityFunctionParameter(name: "bondCreator", type: .address),
            SolidityFunctionParameter(name: "authorizedSortitionPool", type: .address)
        ]
        
        let outputs = [
            SolidityFunctionParameter(name: "_availableUnbondedValue", type: .uint256)
        ]
        
        let method = SolidityConstantFunction(
            name: "availableUnbondedValue",
            inputs: inputs,
            outputs: outputs,
            handler: self
        )
        
        return method.invoke(operatorAddress, bondCreator, authorizedSortitionPool)
    }
    
    func hasSecondaryAuthorization(
        operatorAddress: EthereumAddress,
        sortitionPool: EthereumAddress
    ) -> SolidityInvocation {
        let inputs = [
            SolidityFunctionParameter(name: "_operator", type: .address),
            SolidityFunctionParameter(name: "_poolAddress", type: .address),
        ]
        
        let outputs = [
            SolidityFunctionParameter(name: "_hasSecondaryAuthorization", type: .bool)
        ]
        
        let method = SolidityConstantFunction(
            name: "hasSecondaryAuthorization",
            inputs: inputs,
            outputs: outputs,
            handler: self
        )
        
        return method.invoke(operatorAddress, sortitionPool)
    }
}
