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
    static let testNetAddress = EthereumAddress(hexString: "0xb37c8696cD023c11357B37b5b12A9884c9C83784")!
    
    func getSortitionPool(applicationAddress: EthereumAddress) -> SolidityInvocation {
        let inputs = [SolidityFunctionParameter(name: "_application", type: .address)]
        let outputs = [SolidityFunctionParameter(name: "_getSortitionPool", type: .address)]
        let method = SolidityConstantFunction(name: "getSortitionPool", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke(applicationAddress)
    }
}
