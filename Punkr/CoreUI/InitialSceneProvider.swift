// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Core

struct InitialSceneProvider {

    static func initialScene() -> UIInitialSceneType {
        return .tabs(
            tabsControllerType: UIHomeScreenTabsController.self,
            tabSceneTypes: UIGlobalSceneRouter.tabSceneTypes,
            initialTabIndex: UIGlobalSceneRouter.defaultInitialTabIndex)
    }

}
