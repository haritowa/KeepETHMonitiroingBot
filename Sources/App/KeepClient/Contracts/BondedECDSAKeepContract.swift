//
//  BondedECDSAKeepContract.swift
//  
//
//  Created by Anton Kharchenko on 8/28/20.
//

import Foundation

import Web3
import Web3ContractABI

class BondedECDSAKeepContract: GenericERC20Contract {
    var members: SolidityInvocation {
        let inputs = [SolidityFunctionParameter]()
        let outputs = [SolidityFunctionParameter(name: "_getMembers", type: .array(type: .address, length: nil))]
        let method = SolidityConstantFunction(name: "getMembers", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke()
    }
}
