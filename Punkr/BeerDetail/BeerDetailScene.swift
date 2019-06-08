// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift

public struct BeerDetailScene: ParameterizedUIScene {

    private let _sceneIsInitialized = MutableProperty<Bool>(false)
    public let sceneIsInitialized: Property<Bool>

    public struct Parameters {
        let beer: Beer
        let isSubview: Bool
    }

    private final class Components {
        var interactor: BeerDetailInteractorProtocol!
        var presenter: BeerDetailPresenterProtocol!
        var view: BeerDetailViewProtocol!
        var router: BeerDetailRouterProtocol!
    }

    private let components = Components()
    private var workerQueueScheduler: QueueScheduler!

    public init() {
        sceneIsInitialized = Property(_sceneIsInitialized)

        DispatchQueue.main.executeSync {
            let components = self.components
            let _sceneIsInitialized = self._sceneIsInitialized
            let sceneIsInitialized = self.sceneIsInitialized

            components.view = InstanceProvider.shared.instance(for: BeerDetailViewProtocol.self, defaultInstance: BeerDetailView())
            components.router = InstanceProvider.shared.instance(for: BeerDetailRouterProtocol.self, defaultInstance: BeerDetailRouter())

            let workerQueueLabel = DispatchQueue.uniqueQueueLabel()
            let workerQueueScheduler = QueueScheduler(qos: workerQueueSchedulerQos, name: workerQueueLabel)
            self.workerQueueScheduler = workerQueueScheduler

            workerQueueScheduler.schedule {
                components.interactor =
                    InstanceProvider.shared.instance(for: BeerDetailInteractorProtocol.self, defaultInstance: BeerDetailInteractor())
                components.presenter =
                    InstanceProvider.shared.instance(for: BeerDetailPresenterProtocol.self, defaultInstance: BeerDetailPresenter())

                components.interactor.wireIn(
                    sceneIsInitialized: sceneIsInitialized, presenter: components.presenter, view: components.view,
                    workerQueueScheduler: workerQueueScheduler)
                components.presenter.wireIn(
                    sceneIsInitialized: sceneIsInitialized, interactor: components.interactor, view: components.view,
                    workerQueueScheduler: workerQueueScheduler)

                DispatchQueue.main.executeSync {
                    components.view.wireIn(interactor: components.interactor, presenter: components.presenter)
                    components.router.wireIn(
                        interactor: components.interactor, presenter: components.presenter, view: components.view,
                        workerQueueScheduler: workerQueueScheduler)

                    _sceneIsInitialized.value = true
                }
            }
        }
    }

    public func setParameters(_ parameters: Parameters) {
        sceneIsInitialized.producer
            .filter { $0 }
            .observe(on: workerQueueScheduler)
            .startWithValues { [components] _ in
                components.interactor.setParameters(parameters)
            }
    }

    public var viewController: UIViewController {
        return components.view as! UIViewController
    }

}
