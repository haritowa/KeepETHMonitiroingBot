//
//  Web3+GetLogs.swift
//  
//
//  Created by Anton Kharchenko on 8/29/20.
//

import Foundation

import Web3
import Web3ContractABI

struct EtherumLogsRequest: Codable {
    let address: EthereumAddress
    let fromBlock: EthereumQuantityTag
    let toBlock: EthereumQuantityTag
    let topics: [EthereumData]?
}

extension Web3.Eth {
    func getLogs(
        address: EthereumAddress,
        fromBlock: EthereumQuantityTag = .earliest,
        toBlock: EthereumQuantityTag = .latest,
        topics: [EthereumData]? = nil,
        response: @escaping Web3.Web3ResponseCompletion<[EthereumLogObject]>
    ) {
        let request = EtherumLogsRequest(
            address: address,
            fromBlock: fromBlock,
            toBlock: toBlock,
            topics: topics
        )
        
        let req = RPCRequest(
            id: properties.rpcId,
            jsonrpc: Web3.jsonrpc,
            method: "eth_getLogs",
            params: [request]
        )

        properties.provider.send(request: req, response: response)
    }
    
    func getEvents(
        address: EthereumAddress,
        event: SolidityEvent,
        fromBlock: EthereumQuantityTag = .earliest,
        toBlock: EthereumQuantityTag = .latest,
        response: @escaping (Swift.Result<[[String: Any]], Error>) -> Void
    ) {
        let signature = EthereumData(ABI.encodeEventSignature(event).hexToBytes())
        
        getLogs(
            address: address,
            fromBlock: fromBlock,
            toBlock: toBlock,
            topics: [signature])
        { getLogsResponse in
            let result = getLogsResponse.asResult()
            
            let decodedEvents = result.map { logs in
                logs.compactMap { log in
                    try? ABI.decodeLog(event: event, from: log)
                }
            }
            
            response(decodedEvents)
        }
    }
}
