// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import ReactiveSwift
import Result

// MARK: - Protocol

public protocol PunkServiceProtocol {
    func requestingAllBeers(page: Int) -> SignalProducer<[Beer], Error>
    func requestingBeers(nameQuery: String, page: Int) -> SignalProducer<[Beer], Error>
    func requestingRandomBeer() -> SignalProducer<Beer, Error>
    func requestingBeers(ids: [Int], page: Int) -> SignalProducer<[Beer], Error>
}

// MARK: - Implementation

private let logCategory = "Punk Service"

public final class PunkService: PunkServiceProtocol {

    private let jsonDeserializationQueueScheduler: QueueScheduler = {
        let queueLabel = DispatchQueue.uniqueQueueLabel()
        return QueueScheduler(qos: .utility, name: queueLabel)
    }()

    public static let itemsPerPage = 25

    private typealias `Self` = PunkService

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Requesting

    public func requestingAllBeers(page: Int) -> SignalProducer<[Beer], Error> {
        return requestingBeersSignalProducer(page: page, nameQuery: nil, ids: nil)
    }

    public func requestingBeers(nameQuery: String, page: Int) -> SignalProducer<[Beer], Error> {
        return requestingBeersSignalProducer(page: page, nameQuery: nameQuery, ids: nil)
    }

    public func requestingBeers(ids: [Int], page: Int) -> SignalProducer<[Beer], Error> {
        return requestingBeersSignalProducer(page: page, nameQuery: nil, ids: ids)
    }

    private func requestingBeersSignalProducer(page: Int, nameQuery: String?, ids: [Int]?) -> SignalProducer<[Beer], Error> {
        let endpoint = Backend.API.V2.beers(page: page, itemsPerPage: Self.itemsPerPage, nameQuery: nameQuery, ids: ids)
        let request = endpoint.request
        return
            BackendAPIRequester.making(request)
            .map { response -> Data in
                return response.payload
            }
            .flatMap(.latest) { [jsonDeserializationQueueScheduler] data -> SignalProducer<[Beer], Error> in
                return
                    SignalProducer(value: data)
                    .start(on: jsonDeserializationQueueScheduler)
                    .attemptMap { data -> Result<[Beer], Error> in
                        do {
                            let beers = try JSONDecoder().decode([Beer].self, from: data)
                            log.debug("Received \(beers.count) beers", logCategory)
                            return .success(beers)
                        } catch {
                            log.error("Could not deserialize beers data: \(error.localizedDescription)", logCategory)
                            return .failure(.apiEntityDeserializationError)
                        }
                    }
            }
    }

    public func requestingRandomBeer() -> SignalProducer<Beer, Error> {
        let endpoint = Backend.API.V2.Beers.random
        let request = endpoint.request
        return
            BackendAPIRequester.making(request)
            .map { response -> Data in
                return response.payload
            }
            .flatMap(.latest) { [jsonDeserializationQueueScheduler] data -> SignalProducer<Beer, Error> in
                return
                    SignalProducer(value: data)
                    .start(on: jsonDeserializationQueueScheduler)
                    .attemptMap { data -> Result<Beer, Error> in
                        do {
                            let beers = try JSONDecoder().decode([Beer].self, from: data)
                            if let beer = beers.first {
                                log.debug("Received a random beer", logCategory)
                                return .success(beer)
                            } else {
                                log.error("Unexpectedly received an empty array for a random beer", logCategory)
                                return .failure(.apiEntityDeserializationError)
                            }
                        } catch {
                            log.error("Could not deserialize beers data: \(error.localizedDescription)", logCategory)
                            return .failure(.apiEntityDeserializationError)
                        }
                    }
            }
    }

}
