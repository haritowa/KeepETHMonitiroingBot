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
    static let contractAddress = EthereumAddress(hexString: "0x27321f84704a599aB740281E285cc4463d89A3D5")!
    
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
