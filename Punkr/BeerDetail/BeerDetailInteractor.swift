// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol BeerDetailInteractorProtocol {
    func setParameters(_ parameters: BeerDetailScene.Parameters)
    func wireIn(sceneIsInitialized: Property<Bool>, presenter: BeerDetailPresenterProtocol, view: BeerDetailViewProtocol, workerQueueScheduler: QueueScheduler)
    var requestSignal: Signal<BeerDetailInteractor.Request, NoError> { get }
}

// MARK: - Implementation

final class BeerDetailInteractor: BeerDetailInteractorProtocol, RequestEmitter {

    enum Request {
        case showContent(imageURLString: String?, name: String, description: String, isFavorite: SignalProducer<Bool, NoError>, isSubview: Bool)
    }

    private let parameters = MutableProperty<BeerDetailScene.Parameters?>(nil)
    private let isFavorite = MutableProperty<Bool?>(nil)

    func setParameters(_ parameters: BeerDetailScene.Parameters) {
        self.parameters.value = parameters
    }

    func wireIn(
        sceneIsInitialized: Property<Bool>, presenter: BeerDetailPresenterProtocol, view: BeerDetailViewProtocol, workerQueueScheduler: QueueScheduler) {

        SignalProducer.combineLatest(
            sceneIsInitialized.producer.filter { $0 },
            parameters.producer.skipNil())
                .startWithValues { [weak self] _, parameters in
                    guard let strongSelf = self else { return }
                    let beer = parameters.beer

                    if !parameters.isSubview {
                        strongSelf.isFavorite.value = FavoriteBeerStore.shared.beerIDs.contains(beer.id)
                        FavoriteBeerStore.shared.eventSignal
                            .take(duringLifetimeOf: strongSelf)
                            .observeValues { [weak self, beerID = beer.id] event in
                                guard let strongSelf = self else { return }
                                switch event {
                                case let .changed(favoriteBeerIDs):
                                    strongSelf.isFavorite.value = favoriteBeerIDs.contains(beerID)
                                }
                            }
                    }

                    strongSelf.requestEmitter.send(
                        value: .showContent(
                            imageURLString: beer.imageURLString, name: beer.name, description: beer.description,
                            isFavorite: strongSelf.isFavorite.producer.skipNil().skipRepeats(),
                            isSubview: parameters.isSubview))
                }

        view.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { [weak self] event in
                guard let strongSelf = self else { return }
                switch event {
                case .tappedToggleFavoriteBeer:
                    guard let parameters = strongSelf.parameters.value else { break }
                    if var isCurrentlyFavorite = strongSelf.isFavorite.value {
                        isCurrentlyFavorite = !isCurrentlyFavorite
                        strongSelf.isFavorite.value = isCurrentlyFavorite
                        if isCurrentlyFavorite {
                            FavoriteBeerStore.shared.addBeer(withID: parameters.beer.id)
                        } else {
                            FavoriteBeerStore.shared.removeBeer(withID: parameters.beer.id)
                        }
                    }
                }
            }
    }

}
