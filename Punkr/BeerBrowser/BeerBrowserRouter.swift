// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol BeerBrowserRouterProtocol {
    func wireIn(
        interactor: BeerBrowserInteractorProtocol, presenter: BeerBrowserPresenterProtocol, view: BeerBrowserViewProtocol,
        workerQueueScheduler: QueueScheduler)
}

// MARK: - Implementation

final class BeerBrowserRouter: BeerBrowserRouterProtocol {

    func wireIn(
        interactor: BeerBrowserInteractorProtocol, presenter: BeerBrowserPresenterProtocol, view: BeerBrowserViewProtocol,
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
