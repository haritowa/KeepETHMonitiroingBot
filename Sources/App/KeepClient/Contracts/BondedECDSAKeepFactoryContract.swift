//
//  BondedECDSAKeepFactoryContract.swift
//  
//
//  Created by Anton Kharchenko on 8/1/20.
//

import Foundation

import Web3
import Web3ContractABI

class BondedECDSAKeepFactoryContract: GenericERC20Contract {
    static let contractAddress = EthereumAddress(hexString: "0xA7d9E842EFB252389d613dA88EDa3731512e40bD")!
    
    func getSortitionPool(applicationAddress: EthereumAddress) -> SolidityInvocation {
        let inputs = [SolidityFunctionParameter(name: "_application", type: .address)]
        let outputs = [SolidityFunctionParameter(name: "_getSortitionPool", type: .address)]
        let method = SolidityConstantFunction(name: "getSortitionPool", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke(applicationAddress)
    }
}
