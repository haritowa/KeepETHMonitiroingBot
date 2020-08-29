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
    
    var collateralizationPercentage: SolidityInvocation {
        let inputs = [SolidityFunctionParameter]()
        let outputs = [SolidityFunctionParameter(name: "_collateralizationPercentage", type: .uint256)]
        let method = SolidityConstantFunction(name: "collateralizationPercentage", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke()
    }
    
    var undercollateralizedThresholdPercent: SolidityInvocation {
        let inputs = [SolidityFunctionParameter]()
        let outputs = [SolidityFunctionParameter(name: "_undercollateralizedThresholdPercent", type: .uint16)]
        let method = SolidityConstantFunction(name: "undercollateralizedThresholdPercent", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke()
    }
    
    var severelyUndercollateralizedThresholdPercent: SolidityInvocation {
        let inputs = [SolidityFunctionParameter]()
        let outputs = [SolidityFunctionParameter(name: "_severelyUndercollateralizedThresholdPercent", type: .uint16)]
        let method = SolidityConstantFunction(name: "severelyUndercollateralizedThresholdPercent", inputs: inputs, outputs: outputs, handler: self)
        return method.invoke()
    }
}

