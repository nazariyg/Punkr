// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol FavoriteBeersInteractorProtocol {
    func wireIn(
        sceneIsInitialized: Property<Bool>, presenter: FavoriteBeersPresenterProtocol, view: FavoriteBeersViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<FavoriteBeersInteractor.Request, NoError> { get }
    var eventSignal: Signal<FavoriteBeersInteractor.Event, NoError> { get }
}

// MARK: - Implementation

final class FavoriteBeersInteractor: FavoriteBeersInteractorProtocol, RequestEmitter, EventEmitter {

    enum Request {
        case populateList(beers: [Beer], supplementary: Bool)
    }

    enum Event {
        case itemLoadingStarted
        case itemLoadingEnded
        case selectedBeer(Beer)
    }

    private let punkService = InstanceProvider.shared.instance(for: PunkServiceProtocol.self, defaultInstance: PunkService())
    private var workerQueueScheduler: QueueScheduler!
    private var currentPageIndex = 0
    private var items: [Beer] = []

    func wireIn(
        sceneIsInitialized: Property<Bool>, presenter: FavoriteBeersPresenterProtocol, view: FavoriteBeersViewProtocol, workerQueueScheduler: QueueScheduler) {

        self.workerQueueScheduler = workerQueueScheduler

        sceneIsInitialized.producer
            .observe(on: workerQueueScheduler)
            .filter { $0 }
            .startWithValues { [weak self] _ in
                guard let strongSelf = self else { return }
                let beerIDs = FavoriteBeerStore.shared.beerIDs
                strongSelf.loadItems(beerIDs: beerIDs, supplementary: false)
            }

        view.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case let .selectedBeer(id):
                    if let beer = strongSelf.items.first(where: { $0.id == id }) {
                        strongSelf.eventEmitter.send(value: .selectedBeer(beer))
                    }
                case let .removedBeer(id):
                    strongSelf.items.removeAll(where: { $0.id == id })
                    FavoriteBeerStore.shared.removeBeer(withID: id)
                }
            }

        FavoriteBeerStore.shared.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case let .changed(favoriteBeerIDs):
                    let favoriteBeerIDsSet = Set(favoriteBeerIDs)
                    let currentIDsSet = Set(strongSelf.items.map({ $0.id}))

                    let removedIDsSet = currentIDsSet.subtracting(favoriteBeerIDsSet)
                    if removedIDsSet.isNotEmpty {
                        strongSelf.items.removeAll(where: { removedIDsSet.contains($0.id) })
                        strongSelf.requestEmitter.send(value: .populateList(beers: strongSelf.items, supplementary: false))
                    }

                    let addedIDsSet = favoriteBeerIDsSet.subtracting(currentIDsSet)
                    if addedIDsSet.isNotEmpty {
                        strongSelf.loadItems(beerIDs: Array(addedIDsSet), supplementary: true)
                    }
                }
            }
    }

    private func loadItems(beerIDs: [Int], supplementary: Bool) {
        eventEmitter.send(value: .itemLoadingStarted)
        loadNextItems(beerIDs: beerIDs, currentPageIndex: 0, loadedBeers: []) { [weak self] beers in
            guard let strongSelf = self else { return }
            strongSelf.eventEmitter.send(value: .itemLoadingEnded)
            if !supplementary {
                strongSelf.items = beers
            } else {
                strongSelf.items.append(contentsOf: beers)
            }
            strongSelf.requestEmitter.send(value: .populateList(beers: strongSelf.items, supplementary: supplementary))
        }
    }

    private func loadNextItems(beerIDs: [Int], currentPageIndex: Int, loadedBeers: [Beer], completion: @escaping ([Beer]) -> Void) {
        punkService.requestingBeers(ids: beerIDs, page: currentPageIndex)
            .observe(on: workerQueueScheduler)
            .startWithResult { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case let .success(beers):
                    let newLoadedBeers = loadedBeers.appending(contentsOf: beers)
                    let isLastPage = beers.count < PunkService.itemsPerPage
                    if !isLastPage {
                        let nextPageIndex = currentPageIndex + 1
                        strongSelf.loadNextItems(beerIDs: beerIDs, currentPageIndex: nextPageIndex, loadedBeers: newLoadedBeers, completion: completion)
                    } else {
                        completion(newLoadedBeers)
                    }
                case let .failure(error):
                    strongSelf.handleError(error)
                    completion(loadedBeers)
                }
            }
    }

    private func handleError(_ error: Core.Error) {
        ErrorManager.shared.handleError(error)
    }

}
