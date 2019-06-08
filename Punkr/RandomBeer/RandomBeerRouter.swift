// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result

// MARK: - Protocol

protocol RandomBeerRouterProtocol {
    func wireIn(
        interactor: RandomBeerInteractorProtocol, presenter: RandomBeerPresenterProtocol, view: RandomBeerViewProtocol,
        workerQueueScheduler: QueueScheduler)
}

// MARK: - Implementation

final class RandomBeerRouter: RandomBeerRouterProtocol {

    func wireIn(
        interactor: RandomBeerInteractorProtocol, presenter: RandomBeerPresenterProtocol, view: RandomBeerViewProtocol,
        workerQueueScheduler: QueueScheduler) {}

}
