// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol BeerDetailRouterProtocol {
    func wireIn(
        interactor: BeerDetailInteractorProtocol, presenter: BeerDetailPresenterProtocol, view: BeerDetailViewProtocol,
        workerQueueScheduler: QueueScheduler)
}

// MARK: - Implementation

final class BeerDetailRouter: BeerDetailRouterProtocol {

    func wireIn(
        interactor: BeerDetailInteractorProtocol, presenter: BeerDetailPresenterProtocol, view: BeerDetailViewProtocol,
        workerQueueScheduler: QueueScheduler) {}

}
