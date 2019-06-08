// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones

// MARK: - Protocol

public protocol ErrorManagerProtocol {
    func handleError(_ error: Error)
}

// MARK: - Implementation

public final class ErrorManager: ErrorManagerProtocol, SharedInstance {

    public typealias InstanceProtocol = ErrorManagerProtocol
    public static let defaultInstance: InstanceProtocol = ErrorManager()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Error handling

    public func handleError(_ error: Error) {
        let notificationMessage = "error_generic_error_notification".localized
        UINotificationService.shared.flash(message: notificationMessage, type: .error)
    }

}
