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
    static let testNetAddress = EthereumAddress(hexString: "0x14dC06F762E7f4a756825c1A1dA569b3180153cB")!
}
