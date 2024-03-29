// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation

public extension DispatchQueue {

    // MARK: - Shortcuts for global prioritized concurrent queues

    static var userInteractive: DispatchQueue {
        return DispatchQueue.global(qos: .userInteractive)
    }

    static var userInitiated: DispatchQueue {
        return DispatchQueue.global(qos: .userInitiated)
    }

    static var utility: DispatchQueue {
        return DispatchQueue.global(qos: .utility)
    }

    static var background: DispatchQueue {
        return DispatchQueue.global(qos: .background)
    }

    // MARK: - Smarter closure execution by queue instances

    /// Asynchronously runs a void-returning closure, if non-nil, on the selected queue, using `autoreleasepool` if the selected queue is not the main queue.
    func executeAsync(_ work: VoidClosure?) {
        guard let work = work else { return }
        async {
            if Thread.isMainThread {
                work()
            } else {
                // Improve memory management with `autoreleasepool`.
                autoreleasepool {
                    work()
                }
            }
        }
    }

    /// Synchronously runs a void/value-returning non-optional closure, if non-nil, on the selected queue, simply executing the closure in-place if
    /// the selected queue and the current queue are both the main queue, and using `autoreleasepool` if the selected queue is not the main queue.
    @discardableResult
    func executeSync<ReturnType>(_ work: ThrowingReturningClosure<ReturnType>) rethrows -> ReturnType {
        if self === DispatchQueue.main && Thread.isMainThread {
            // Already on the main queue.
            return try work()
        }
        return try sync {
            if Thread.isMainThread {
                return try work()
            } else {
                // Improve memory management with `autoreleasepool`.
                return try autoreleasepool {
                    return try work()
                }
            }
        }
    }

    /// Asynchronously runs a void-returning closure, if non-nil, on the selected queue after the specified delay, using `autoreleasepool` if
    /// the selected queue is not the main queue.
    func executeAsyncAfter(_ delay: TimeInterval, _ work: VoidClosure?) {
        guard let work = work else { return }
        asyncAfter(deadline: .now() + delay, execute: {
            if Thread.isMainThread {
                work()
            } else {
                // Improve memory management with `autoreleasepool`.
                autoreleasepool {
                    work()
                }
            }
        })
    }

    // MARK: - Queue identification

    /// Returns the label of the queue the caller is currently running on.
    static var currentQueueLabel: String {
        let label = String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!
        return label
    }

}
