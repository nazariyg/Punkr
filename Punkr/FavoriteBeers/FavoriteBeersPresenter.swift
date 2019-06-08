// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result
import ReactiveCocoa

// MARK: - Protocol

protocol FavoriteBeersPresenterProtocol {
    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: FavoriteBeersInteractorProtocol, view: FavoriteBeersViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<FavoriteBeersPresenter.Request, NoError> { get }
}

// MARK: - Implementation

final class FavoriteBeersPresenter: FavoriteBeersPresenterProtocol, RequestEmitter {

    enum Request {
        case showLoadingIndicator
        case hideLoadingIndicator
        case populateList(beerViewModels: [FavoriteBeersListEntryViewModel], supplementary: Bool)
    }

    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: FavoriteBeersInteractorProtocol, view: FavoriteBeersViewProtocol,
        workerQueueScheduler: QueueScheduler) {

        interactor.requestSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case let .populateList(beers, supplementary):
                    let beerViewModels = beers.map { FavoriteBeersListEntryViewModel(beer: $0) }
                    strongSelf.requestEmitter.send(value: .populateList(beerViewModels: beerViewModels, supplementary: supplementary))
                }
            }

        interactor.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case .itemLoadingStarted:
                    strongSelf.requestEmitter.send(value: .showLoadingIndicator)
                case .itemLoadingEnded:
                    strongSelf.requestEmitter.send(value: .hideLoadingIndicator)
                default: break
                }
            }
    }

}
