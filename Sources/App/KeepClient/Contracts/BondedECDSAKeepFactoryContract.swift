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
    static let testNetAddress = EthereumAddress(hexString: "0x9EcCf03dFBDa6A5E50d7aBA14e0c60c2F6c575E6")!
    
    func getSortitionPool(applicationAddress: EthereumAddress) -> SolidityInvocation {
        let inputs = [SolidityFunctionParameter(name: "_application", type: .address)]
        let outputs = [SolidityFunctionParameter(name: "_getSortitionPool", type: .address)]
        let method = SolidityConstantFunction(name: "getSortitionPool", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke(applicationAddress)
    }
}
