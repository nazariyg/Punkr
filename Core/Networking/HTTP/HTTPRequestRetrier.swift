// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Alamofire

private let logCategory = "Network"

public struct HTTPRequestRetrier {

    private static let retryingRequestsConfig = Config.shared.general.retryingFailedNetworkRequests

    public func shouldRetryRequest(withRetryCount retryCount: Int, error: Error, responseStatusCode: Int?) -> Bool {
        // In any case, only retry a limited number of times.
        if retryCount >= Self.retryingRequestsConfig.maxRetryCount {
            return false
        }

        // The usual suspects.
        if error == .networkTimedOut {
            // Don't prolong the user's waiting time.
            return false
        }
        if error == .networkingError {
            return true
        }

        // The `responseStatusCode` logic may go here.

        // By default, do not retry.
        return false
    }

    private typealias `Self` = HTTPRequestRetrier

}

extension HTTPRequestRetrier: Alamofire.RequestRetrier {

    public func should(_ manager: SessionManager, retry request: Request, with error: Swift.Error, completion: @escaping RequestRetryCompletion) {
        let responseStatusCode = request.response?.statusCode
        let shouldRetry = shouldRetryRequest(withRetryCount: Int(request.retryCount), error: Error(error), responseStatusCode: responseStatusCode)
        if shouldRetry {
            log.debug("Retrying an HTTP request retried \(request.retryCount) times before:\n\(request)", logCategory)
        }
        completion(shouldRetry, Self.retryingRequestsConfig.retryingTimeDelay)
    }

}
