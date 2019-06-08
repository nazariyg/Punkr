// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol RandomBeerInteractorProtocol {
    func wireIn(sceneIsInitialized: Property<Bool>, presenter: RandomBeerPresenterProtocol, view: RandomBeerViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<RandomBeerInteractor.Request, NoError> { get }
    var eventSignal: Signal<RandomBeerInteractor.Event, NoError> { get }
}

// MARK: - Implementation

final class RandomBeerInteractor: RandomBeerInteractorProtocol, RequestEmitter, EventEmitter {

    enum Request {
        case showContent(imageURLString: String?, name: String, description: String)
    }

    enum Event {
        case itemLoadingStarted
        case itemLoadingEnded
    }

    private let punkService = InstanceProvider.shared.instance(for: PunkServiceProtocol.self, defaultInstance: PunkService())
    private var workerQueueScheduler: QueueScheduler!
    private var loadRandomItemDisposable: Disposable?

    func wireIn(
        sceneIsInitialized: Property<Bool>, presenter: RandomBeerPresenterProtocol, view: RandomBeerViewProtocol, workerQueueScheduler: QueueScheduler) {

        self.workerQueueScheduler = workerQueueScheduler

        sceneIsInitialized.producer
            .observe(on: workerQueueScheduler)
            .filter { $0 }
            .startWithValues { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.loadRandomItem()
            }

        view.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case .tappedRandomButton:
                    strongSelf.loadRandomItem()
                }
            }
    }

    private func loadRandomItem() {
        eventEmitter.send(value: .itemLoadingStarted)
        loadRandomItemDisposable?.dispose()
        loadRandomItemDisposable =
            punkService.requestingRandomBeer()
                .observe(on: workerQueueScheduler)
                .startWithResult { [weak self] result in
                    guard let strongSelf = self else { return }
                    strongSelf.eventEmitter.send(value: .itemLoadingEnded)
                    switch result {
                    case let .success(beer):
                        strongSelf.requestEmitter.send(
                            value: .showContent(imageURLString: beer.imageURLString, name: beer.name, description: beer.description))
                    case let .failure(error):
                        strongSelf.handleError(error)
                    }
                }
    }

    private func handleError(_ error: Core.Error) {
        ErrorManager.shared.handleError(error)
    }

}
