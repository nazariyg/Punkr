// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result
import ReactiveCocoa

// MARK: - Protocol

protocol RandomBeerPresenterProtocol {
    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: RandomBeerInteractorProtocol, view: RandomBeerViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<RandomBeerPresenter.Request, NoError> { get }
}

// MARK: - Implementation

final class RandomBeerPresenter: RandomBeerPresenterProtocol, RequestEmitter {

    enum Request {
        case showLoadingIndicator
        case hideLoadingIndicator
    }

    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: RandomBeerInteractorProtocol, view: RandomBeerViewProtocol, workerQueueScheduler: QueueScheduler) {

        interactor.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case .itemLoadingStarted:
                    strongSelf.requestEmitter.send(value: .showLoadingIndicator)
                case .itemLoadingEnded:
                    strongSelf.requestEmitter.send(value: .hideLoadingIndicator)
                }
            }
    }

}
