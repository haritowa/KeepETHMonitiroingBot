//
//  Etherscan+Telegram.swift
//  
//
//  Created by Anton Kharchenko on 7/28/20.
//

import Foundation

func createEtherscanLink(for address: String) -> String {
    let url = "https://ropsten.etherscan.io/address/\(address)"
    return "[\(createEtherscanShourtcut(for: address))](\(url))"
}

func createEtherscanShourtcut(for address: String) -> String {
    return address.prefix(6) + "..." + address.suffix(4)
}
