// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones

// MARK: - Protocol

public protocol ActivityTrackerProtocol {
    func userAddedBeerToFavorites()
}

// MARK: - Implementation

public final class ActivityTracker: ActivityTrackerProtocol, SharedInstance {

    public typealias InstanceProtocol = ActivityTrackerProtocol
    public static let defaultInstance: InstanceProtocol = ActivityTracker()

    private let activityTrackingService: ActivityTrackingService = DummyActivityTrackingService()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Activity tracking

    public func userAddedBeerToFavorites() {
        activityTrackingService.trackActivity(name: #function)
    }

}
