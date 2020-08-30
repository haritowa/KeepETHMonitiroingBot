//
//  Web3+GetLogs.swift
//  
//
//  Created by Anton Kharchenko on 8/29/20.
//

import Foundation
import Vapor

import Web3
import Web3ContractABI

struct EtherumLogsRequest: Codable {
    let address: EthereumAddress
    let fromBlock: EthereumQuantityTag
    let toBlock: EthereumQuantityTag
    let topics: [EthereumData]?
}

protocol EventDataProtocol {
    init?(args: [String: Any])
}

extension Dictionary where Key == String, Value == Any {
    func cast<T>(for key: String) -> T? {
        self[key] as? T
    }
}

struct EventContainer<Data: EventDataProtocol> {
    let data: Data
    let log: EthereumLogObject
    
    init(data: Data, log: EthereumLogObject) {
        self.data = data
        self.log = log
    }
    
    init?(data: [String: Any], log: EthereumLogObject) {
        guard let eventData = Data(args: data) else { return nil }
        
        self.data = eventData
        self.log = log
    }
}

extension EventContainer: Equatable where Data: Equatable {}
extension EventContainer: Hashable where Data: Hashable { }

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
    
    func getEvents<Data: EventDataProtocol>(
        data: Data.Type = Data.self,
        eventLoop: EventLoop,
        address: EthereumAddress,
        event: SolidityEvent,
        fromBlock: EthereumQuantityTag = .earliest,
        toBlock: EthereumQuantityTag = .latest
    ) -> EventLoopFuture<[EventContainer<Data>]> {
        let signature = EthereumData(ABI.encodeEventSignature(event).hexToBytes())
        let promise: EventLoopPromise<[EventContainer<Data>]> = eventLoop.makePromise()
        
        getLogs(
            address: address,
            fromBlock: fromBlock,
            toBlock: toBlock,
            topics: [signature])
        { getLogsResponse in
            let result = getLogsResponse.asResult()
            
            let decodedEvents = result.map { logs in
                logs.compactMap { log -> EventContainer<Data>? in
                    let args = try? ABI.decodeLog(event: event, from: log)
                    return args.flatMap { EventContainer<Data>(data: $0, log: log) }
                }
            }
            
            promise.completeWith(decodedEvents)
        }
        
        return promise.futureResult
    }
}
