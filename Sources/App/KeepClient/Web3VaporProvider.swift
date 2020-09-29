//
//  Web3VaporProvider.swift
//  
//
//  Created by Anton Kharchenko on 7/26/20.
//

import Foundation
import Vapor
import Web3

extension RPCRequest: Content { }

extension BigUInt: Content { }
extension EthereumAddress: Content { }

class Web3VaporProvider: Web3Provider {
    private let rpcURL: URI
    let client: Client
    
    init(rpcURL: URI, client: Client) {
        self.rpcURL = rpcURL
        self.client = client
    }
    
    func send<Params: Codable, Result: Codable>(request: RPCRequest<Params>, response: @escaping Web3ResponseCompletion<Result>) {
        client.post(
            rpcURL,
            beforeSend: { try $0.content.encode(request) }
        ).flatMapThrowing { try $0.content.decode(RPCResponse<Result>.self) }
        .whenComplete(Self.apply(completion: response))
    }
    
    private static func apply<Data: Codable>(completion: @escaping Web3ResponseCompletion<Data>) -> (Result<RPCResponse<Data>, Error>) -> Void {
        return { result in
            switch result {
            case .success(let value): completion(Web3Response(rpcResponse: value))
            case .failure(let error): completion(Web3Response(error: error))
            }
        }
    }
}

extension Request {
    func web3Provider(rpcURL: URI) -> Web3VaporProvider {
        Web3VaporProvider(rpcURL: rpcURL, client: self.client)
    }
    
    var web3Provider: Web3VaporProvider {
        web3Provider(rpcURL: "https://mainnet.infura.io/v3/\(Environment.get("INFURA_PROJECT_ID") ?? "")")
    }
}

extension Application {
    func web3Provider(rpcURL: URI) -> Web3VaporProvider {
        Web3VaporProvider(rpcURL: rpcURL, client: self.client)
    }
    
    var web3Provider: Web3VaporProvider {
        web3Provider(rpcURL: "https://mainnet.infura.io/v3/\(Environment.get("INFURA_PROJECT_ID") ?? "")")
    }
}
