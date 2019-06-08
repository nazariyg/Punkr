// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol FavoriteBeersRouterProtocol {
    func wireIn(
        interactor: FavoriteBeersInteractorProtocol, presenter: FavoriteBeersPresenterProtocol, view: FavoriteBeersViewProtocol,
        workerQueueScheduler: QueueScheduler)
}

// MARK: - Implementation

final class FavoriteBeersRouter: FavoriteBeersRouterProtocol {

    func wireIn(
        interactor: FavoriteBeersInteractorProtocol, presenter: FavoriteBeersPresenterProtocol, view: FavoriteBeersViewProtocol,
        workerQueueScheduler: QueueScheduler) {

        interactor.eventSignal
            .observe(on: workerQueueScheduler)
            .observeValues { event in
                switch event {
                case let .selectedBeer(beer):
                    let parameters = BeerDetailScene.Parameters(beer: beer, isSubview: false)
                    UIGlobalSceneRouter.shared.go(BeerDetailScene.self, parameters: parameters)
                default: break
                }
            }
    }

}
