// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result
import ReactiveCocoa

// MARK: - Protocol

protocol BeerDetailPresenterProtocol {
    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: BeerDetailInteractorProtocol, view: BeerDetailViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<BeerDetailPresenter.Request, NoError> { get }
}

// MARK: - Implementation

final class BeerDetailPresenter: BeerDetailPresenterProtocol, RequestEmitter {

    enum Request {
        case showContent(entryViewModels: [BeerDetailEntryViewModel], isFavorite: SignalProducer<Bool, NoError>, isSubview: Bool)
    }

    func wireIn(
        sceneIsInitialized: Property<Bool>, interactor: BeerDetailInteractorProtocol, view: BeerDetailViewProtocol, workerQueueScheduler: QueueScheduler) {

        interactor.requestSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case let .showContent(imageURLString, name, description, isFavorite, isSubview):
                    let entryViewModels = [
                        BeerDetailEntryViewModel(imageURLString: imageURLString),
                        BeerDetailEntryViewModel(name: name),
                        BeerDetailEntryViewModel(description: description)
                    ]
                    strongSelf.requestEmitter.send(value: .showContent(entryViewModels: entryViewModels, isFavorite: isFavorite, isSubview: isSubview))
                }
            }
    }

}
