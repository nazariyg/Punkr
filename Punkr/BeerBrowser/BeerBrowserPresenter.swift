// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result
import ReactiveCocoa

// MARK: - Protocol

protocol BeerBrowserPresenterProtocol {
    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: BeerBrowserInteractorProtocol, view: BeerBrowserViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<BeerBrowserPresenter.Request, NoError> { get }
}

// MARK: - Implementation

final class BeerBrowserPresenter: BeerBrowserPresenterProtocol, RequestEmitter {

    enum Request {
        case showInitialLoadingIndicator
        case hideInitialLoadingIndicator
        case populateList(beerViewModels: [BeerBrowserListEntryViewModel], isLastPage: Bool)
        case showNextPageLoadingIndicator
        case hideNextPageLoadingIndicator
    }

    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: BeerBrowserInteractorProtocol, view: BeerBrowserViewProtocol, workerQueueScheduler: QueueScheduler) {

        interactor.requestSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case let .populateList(beers, isLastPage):
                    let beerViewModels = beers.map { BeerBrowserListEntryViewModel(beer: $0) }
                    strongSelf.requestEmitter.send(value: .populateList(beerViewModels: beerViewModels, isLastPage: isLastPage))
                default: break
                }
            }

        interactor.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case .initialItemLoadingStarted:
                    strongSelf.requestEmitter.send(value: .showInitialLoadingIndicator)
                case .initialItemLoadingEnded:
                    strongSelf.requestEmitter.send(value: .hideInitialLoadingIndicator)
                case .nextPageItemLoadingStarted:
                    strongSelf.requestEmitter.send(value: .showNextPageLoadingIndicator)
                case .nextPageItemLoadingEnded:
                    strongSelf.requestEmitter.send(value: .hideNextPageLoadingIndicator)
                default: break
                }
            }
    }

}
