// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import ReactiveSwift

// MARK: - Protocol

public protocol UIProtocol {
    var isInitialized: MutableProperty<Bool> { get }
    var homeScreenHasInitiallyShown: MutableProperty<Bool> { get }
    func initUI(initialScene: UIInitialSceneType) -> UIWindow
    func setGlobalBackgroundColor(_ color: UIColor)
    func resetGlobalBackgroundColor()
}

// MARK: - Implementation

public final class UI: UIProtocol, SharedInstance {

    public typealias InstanceProtocol = UIProtocol
    public static var defaultInstance: UIProtocol = UI()

    /// Subscribers should manually skip repeats, if needed.
    public let isInitialized = MutableProperty<Bool>(false)
    public let homeScreenHasInitiallyShown = MutableProperty<Bool>(false)

    // MARK: - Lifecycle

    private init() {}

    // MARK: - UI

    public func initUI(initialScene: UIInitialSceneType) -> UIWindow {
        return DispatchQueue.main.executeSync {
            let screenSize = UIScreen.main.bounds.size
            let window = UIWindow(frame: CGRect(origin: .zero, size: screenSize))

            window.rootViewController = UIRootViewControllerContainer.shared as? UIViewController

            let backgroundColor = Config.shared.appearance.windowBackgroundColor
            window.backgroundColor = backgroundColor
            UIRootViewControllerContainer.shared.view.backgroundColor = backgroundColor

            window.makeKeyAndVisible()

            switch initialScene {
            case let .scene(sceneType):
                UIScener.shared.initialize(initialSceneType: sceneType)
            case let .tabs(tabsControllerType, tabSceneTypes, initialTabIndex):
                UIScener.shared.initialize(
                    tabsControllerType: tabsControllerType, initialSceneTypes: tabSceneTypes,
                    initialTabIndex: initialTabIndex, completion: {
                        UI.shared.homeScreenHasInitiallyShown.value = true
                    })
            }

            return window
        }
    }

    public func setGlobalBackgroundColor(_ color: UIColor) {
        DispatchQueue.main.executeSync {
            UIApplication.shared.keyWindow?.backgroundColor = color
            UIRootViewControllerContainer.shared.view.backgroundColor = color
        }
    }

    public func resetGlobalBackgroundColor() {
        DispatchQueue.main.executeSync {
            let backgroundColor = Config.shared.appearance.windowBackgroundColor
            UIApplication.shared.keyWindow?.backgroundColor = backgroundColor
            UIRootViewControllerContainer.shared.view.backgroundColor = backgroundColor
        }
    }

}
