//
//  CollateralizationPollingJob.swift
//  
//
//  Created by Anton Kharchenko on 8/30/20.
//

import Foundation
import Vapor

import Web3

struct FetchedCollateralizationAlert {
    let operatorAddress: EthereumAddress
    let depositAddress: EthereumAddress
    let date: Date
    let isSeverelyUndercollateralized: Bool
}

struct CollateralizationPollingFetchResult {
    let latestBlock: String?
    
    // Operator address -> alerts
    let alerts: [String: [FetchedCollateralizationAlert]]
}

struct CollateralizationFetchRoutine {
    private static let maxAlertAge = TimeInterval(6 * 60 * 60)
    
    let fromBlock: EthereumQuantityTag
    
    let eventLoop: EventLoop
    let web3: Web3
    let keepClient: KeepClientProtocol
    
    func perform() -> EventLoopFuture<CollateralizationPollingFetchResult> {
        getEvents()
        .map(process)
        .flatMap { actualEvents, newTag in
            self.createAlerts(for: actualEvents).map { CollateralizationPollingFetchResult(latestBlock: newTag, alerts: $0) }
        }
    }
    
    private func getEvents() -> EventLoopFuture<[EventContainer<CourtesyCalledEventData>]> {
        web3.eth.getEvents(
            data: CourtesyCalledEventData.self,
            eventLoop: eventLoop,
            address: TBTCSystemContract.contractAddress,
            event: TBTCSystemContract.CourtesyCalled,
            fromBlock: fromBlock
        )
    }
    
    private func createAlerts(
        for actualEvents: Set<EventContainer<CourtesyCalledEventData>>
    ) -> EventLoopFuture<[String: [FetchedCollateralizationAlert]]> {
        getDepositState(events: actualEvents)
            .flatMap(mapDepositStates)
    }
    
    private func process(
        events: [EventContainer<CourtesyCalledEventData>]
    ) -> (actualEvents: Set<EventContainer<CourtesyCalledEventData>>, newTag: String?) {
        let sortedEvents = events.sorted { $0.data.timestamp > $1.data.timestamp }
        let filteredEvents = sortedEvents
            .filter { -$0.data.timestamp.timeIntervalSinceNow < Self.maxAlertAge }
        
        let newTagData = sortedEvents
            .first(where: { -$0.data.timestamp.timeIntervalSinceNow >= Self.maxAlertAge })?
            .log
            .blockNumber?
            .hex()
    
        let eventsSet = Set(filteredEvents)
        return (eventsSet, newTagData)
    }
    
    private func getDepositState(
        event: EventContainer<CourtesyCalledEventData>
    ) -> EventLoopFuture<(CourtesyCalledEventData, DepostCollateralizationState)> {
        keepClient
            .depositState(depositAddress: event.data.depositContractAddress)
            .map { (event.data, $0) }
    }
    
    private func getDepositState(
        events: Set<EventContainer<CourtesyCalledEventData>>
    ) -> EventLoopFuture<[CourtesyCalledEventData: DepostCollateralizationState]> {
        EventLoopFuture.whenAllSucceed(
            events.map(getDepositState),
            on: eventLoop
        )
            .map([CourtesyCalledEventData: DepostCollateralizationState].init(uniqueKeysWithValues:))
    }
    
    private func getMapping(for event: CourtesyCalledEventData, state: DepostCollateralizationState) -> EventLoopFuture<[FetchedCollateralizationAlert]> {
        guard state != .normal else {
            return eventLoop.makeSucceededFuture([])
        }
        
        return keepClient
        .operators(for: event.depositContractAddress)
        .map { operators in
            operators.map { participant in
                FetchedCollateralizationAlert(
                    operatorAddress: participant,
                    depositAddress: event.depositContractAddress,
                    date: event.timestamp,
                    isSeverelyUndercollateralized: state == .severelyUndercollateralized
                )
            }
        }
    }
    
    private func mapDepositStates(
        events: [CourtesyCalledEventData: DepostCollateralizationState]
    ) -> EventLoopFuture<[String: [FetchedCollateralizationAlert]]> {
        EventLoopFuture.reduce(
            into: [String: [FetchedCollateralizationAlert]](),
            events.map { getMapping(for: $0.key, state: $0.value) },
            on: eventLoop
        ) { (acc, currentBatch) in
            currentBatch.forEach { item in
                let key = item.operatorAddress.hex(eip55: true)
                var currentValue = acc[key] ?? []
                currentValue.append(item)
                acc[key] = currentValue
            }
        }
    }
}
