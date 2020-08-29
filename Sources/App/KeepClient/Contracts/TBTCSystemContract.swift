//
//  TBTCSystemContract.swift
//  
//
//  Created by Anton Kharchenko on 8/1/20.
//

import Foundation

import Web3
import Web3ContractABI

class TBTCSystemContract: GenericERC20Contract {
    static let testNetAddress = EthereumAddress(hexString: "0x9F3B3bCED0AFfe862D436CB8FF462a454040Af80")!
    
    open override var events: [SolidityEvent] {
        var superEvents = super.events
        superEvents.append(TBTCSystemContract.Created)
        superEvents.append(TBTCSystemContract.CourtesyCalled)
        return superEvents
    }
    
    static var Created: SolidityEvent {
        let inputs: [SolidityEvent.Parameter] = [
            SolidityEvent.Parameter(name: "_depositContractAddress", type: .address, indexed: true),
            SolidityEvent.Parameter(name: "_keepAddress", type: .address, indexed: true),
            SolidityEvent.Parameter(name: "_timestamp", type: .uint256, indexed: false)
        ]
        
        return SolidityEvent(name: "Created", anonymous: false, inputs: inputs)
    }
    
    static var CourtesyCalled: SolidityEvent {
        let inputs: [SolidityEvent.Parameter] = [
            SolidityEvent.Parameter(name: "_depositContractAddress", type: .address, indexed: true),
            SolidityEvent.Parameter(name: "_timestamp", type: .uint256, indexed: false)
        ]
        
        return SolidityEvent(name: "CourtesyCalled", anonymous: false, inputs: inputs)
    }
}
