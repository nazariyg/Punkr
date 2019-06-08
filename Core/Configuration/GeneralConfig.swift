// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import UserNotifications
import Cornerstones

public struct RetryingFailedNetworkRequestsConfig {
    public let shouldRetry: Bool
    public let maxRetryCount: Int
    public let retryingTimeDelay: TimeInterval
}

public protocol GeneralConfig {

    var appName: String { get }

    var acknowledgeServerErrors: Bool { get }
    var acknowledgeHTTPResponseNotFoundErrors: Bool { get }
    var acknowledgeHTTPResponseErrorCodes: Bool { get }
    var retryingFailedNetworkRequests: RetryingFailedNetworkRequestsConfig { get }
    var httpRequestSendUserAgentHeader: Bool { get }
    var httpRequestSendAcceptLanguageHeader: Bool { get }
    var logHTTPResponseData: Bool { get }
    var maxHTTPResponseDataSizeForLogging: Int { get }

}

// All environments.
public extension GeneralConfig {

    var appName: String { return UserDefinedBuildSettings.string[#function] }

    var retryingFailedNetworkRequests: RetryingFailedNetworkRequestsConfig {
        return
            RetryingFailedNetworkRequestsConfig(
                shouldRetry: true,
                maxRetryCount: 3,
                retryingTimeDelay: 1)
    }

    var acknowledgeServerErrors: Bool { return true }
    var acknowledgeHTTPResponseNotFoundErrors: Bool { return true }
    var acknowledgeHTTPResponseErrorCodes: Bool { return true }
    var httpRequestSendUserAgentHeader: Bool { return false }
    var httpRequestSendAcceptLanguageHeader: Bool { return false }
    var logHTTPResponseData: Bool { return false }
    var maxHTTPResponseDataSizeForLogging: Int { return 1024 }

}

// Dev environment.
public struct GeneralConfigDev: GeneralConfig {
    // Customization.
}

// Prod environment.
public struct GeneralConfigProd: GeneralConfig {
    // Customization.
}
