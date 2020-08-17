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
}
