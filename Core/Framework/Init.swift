// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation

public func initialize() {
    DispatchQueue.main.executeSync {
        _ = Network.shared
        _ = UINetworkStatusNotifier.shared
    }
}
