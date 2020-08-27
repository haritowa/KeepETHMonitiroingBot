//
//  DepositContract.swift
//  
//
//  Created by Anton Kharchenko on 8/28/20.
//

import Foundation

import Web3
import Web3ContractABI

class DepositContract: GenericERC20Contract {
    var keepAddress: SolidityInvocation {
        let inputs = [SolidityFunctionParameter]()
        let outputs = [SolidityFunctionParameter(name: "_keepAddress", type: .address)]
        let method = SolidityConstantFunction(name: "keepAddress", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke()
    }
}
