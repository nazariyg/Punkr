// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol BeerBrowserInteractorProtocol {
    func wireIn(
        sceneIsInitialized: Property<Bool>, presenter: BeerBrowserPresenterProtocol, view: BeerBrowserViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<BeerBrowserInteractor.Request, NoError> { get }
    var eventSignal: Signal<BeerBrowserInteractor.Event, NoError> { get }
}

// MARK: - Implementation

final class BeerBrowserInteractor: BeerBrowserInteractorProtocol, RequestEmitter, EventEmitter {

    enum Request {
        case populateList(beers: [Beer], isLastPage: Bool)
        case clearList
    }

    enum Event {
        case initialItemLoadingStarted
        case initialItemLoadingEnded
        case nextPageItemLoadingStarted
        case nextPageItemLoadingEnded
        case selectedBeer(Beer)
    }

    private enum BrowsingMode {
        case listing(currentPageIndex: Int)
        case searching(nameQuery: String, currentPageIndex: Int)
    }

    private let punkService = InstanceProvider.shared.instance(for: PunkServiceProtocol.self, defaultInstance: PunkService())
    private var workerQueueScheduler: QueueScheduler!
    private var browsingMode: BrowsingMode = .listing(currentPageIndex: 0)
    private var items: [Beer] = []
    private var beerNameSearchingDisposable: Disposable?

    func wireIn(
        sceneIsInitialized: Property<Bool>, presenter: BeerBrowserPresenterProtocol, view: BeerBrowserViewProtocol, workerQueueScheduler: QueueScheduler) {

        self.workerQueueScheduler = workerQueueScheduler

        sceneIsInitialized.producer
            .observe(on: workerQueueScheduler)
            .filter { $0 }
            .startWithValues { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.loadItems()
            }

        view.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case .scrolledToEnd:
                    strongSelf.loadNextPage()
                case .enteredListingMode:
                    strongSelf.items = []
                    strongSelf.requestEmitter.send(value: .clearList)
                    strongSelf.browsingMode = .listing(currentPageIndex: 0)
                    strongSelf.loadItems()
                case let .selectedBeer(id):
                    if let beer = strongSelf.items.first(where: { $0.id == id }) {
                        strongSelf.eventEmitter.send(value: .selectedBeer(beer))
                    }
                default: break
                }
            }

        view.eventSignal
            .observe(on: workerQueueScheduler)
            .debounce(0.5, on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case let .enteredSearchMode(searchText):
                    strongSelf.items = []
                    strongSelf.requestEmitter.send(value: .clearList)
                    strongSelf.browsingMode = .searching(nameQuery: searchText, currentPageIndex: 0)
                    strongSelf.loadItems()
                default: break
                }
            }
    }

    private func loadItems() {
        switch browsingMode {

        case let .listing(currentPageIndex):
            eventEmitter.send(value: currentPageIndex == 0 ? .initialItemLoadingStarted : .nextPageItemLoadingStarted)
            punkService.requestingAllBeers(page: currentPageIndex)
                .observe(on: workerQueueScheduler)
                .startWithResult { [weak self] result in
                    guard let strongSelf = self else { return }
                    strongSelf.eventEmitter.send(value: currentPageIndex == 0 ? .initialItemLoadingEnded : .nextPageItemLoadingEnded)
                    switch result {
                    case let .success(beers):
                        strongSelf.items.append(contentsOf: beers)
                        let isLastPage = beers.count < PunkService.itemsPerPage
                        strongSelf.requestEmitter.send(value: .populateList(beers: strongSelf.items, isLastPage: isLastPage))
                    case let .failure(error):
                        strongSelf.handleError(error)
                    }
                }

        case let .searching(nameQuery, currentPageIndex):
            eventEmitter.send(value: currentPageIndex == 0 ? .initialItemLoadingStarted : .nextPageItemLoadingStarted)
            beerNameSearchingDisposable?.dispose()
            beerNameSearchingDisposable =
                punkService.requestingBeers(nameQuery: nameQuery, page: currentPageIndex)
                    .observe(on: workerQueueScheduler)
                    .startWithResult { [weak self] result in
                        guard let strongSelf = self else { return }
                        strongSelf.eventEmitter.send(value: currentPageIndex == 0 ? .initialItemLoadingEnded : .nextPageItemLoadingEnded)
                        switch result {
                        case let .success(beers):
                            strongSelf.items.append(contentsOf: beers)
                            let isLastPage = beers.count < PunkService.itemsPerPage
                            strongSelf.requestEmitter.send(value: .populateList(beers: strongSelf.items, isLastPage: isLastPage))
                        case let .failure(error):
                            strongSelf.handleError(error)
                        }
                    }

        }
    }

    private func loadNextPage() {
        switch browsingMode {

        case let .listing(currentPageIndex):
            let nextPageIndex = currentPageIndex + 1
            browsingMode = .listing(currentPageIndex: nextPageIndex)
            loadItems()

        case let .searching(nameQuery, currentPageIndex):
            let nextPageIndex = currentPageIndex + 1
            browsingMode = .searching(nameQuery: nameQuery, currentPageIndex: nextPageIndex)
            loadItems()

        }
    }

    private func handleError(_ error: Core.Error) {
        ErrorManager.shared.handleError(error)
    }

}
