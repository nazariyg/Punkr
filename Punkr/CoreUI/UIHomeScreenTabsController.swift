// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Core

final class UIHomeScreenTabsController: UITabBarController, UITabsController {

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        tabBar.barStyle = .black
        tabBar.tintColor = .white
        delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTabs()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setTabBarHeight()
    }

    // MARK: - Private

    private func configureTabs() {
        guard let viewControllers = viewControllers else { return }
        viewControllers[0].tabBarItem = UITabBarItem(title: nil, image: R.image.tabBeerBrowser(), tag: 0)
        viewControllers[1].tabBarItem = UITabBarItem(title: nil, image: R.image.tabRandomBeer(), tag: 0)
        viewControllers[2].tabBarItem = UITabBarItem(title: nil, image: R.image.tabFavoriteBeers(), tag: 0)
    }

    var tabBarHeight: CGFloat {
        return 80 + view.safeAreaInsets.bottom
    }

    private func setTabBarHeight() {
        var tabFrame = tabBar.frame
        tabFrame.size.height = tabBarHeight
        tabFrame.origin.y = view.frame.size.height - tabBarHeight
        tabBar.frame = tabFrame
    }

}

extension UIHomeScreenTabsController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard
            let viewControllers = viewControllers,
            let index = viewControllers.firstIndex(where: { $0 === viewController })
            else { return }
        UIScener.shared._updateTabIndex(index)
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let fromView = selectedViewController?.view, let toView = viewController.view else { return false }
        if fromView != toView {
            UIView.transition(from: fromView, to: toView, duration: 0.15, options: .transitionCrossDissolve, completion: nil)
        }
        return true
    }

}
