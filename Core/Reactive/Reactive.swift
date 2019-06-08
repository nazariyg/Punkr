// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import ReactiveSwift
import Result
import ReactiveCocoa

public extension Reactive where Base: NSObject {

    func producer<Value>(forKeyPath keyPath: String) -> SignalProducer<Value?, NoError> {
        return producer(forKeyPath: keyPath).map { $0 as? Value }
    }

}
