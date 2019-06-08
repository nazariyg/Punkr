// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones

public extension Backend.API.V2 {

    var request: HTTPRequest {

        switch self {

        case let .beers(page, itemsPerPage, nameQuery, ids):
            var parameters: [String: Any] = [:]
            if let page = page {
                let apiPage = page + 1
                parameters["page"] = apiPage
            }
            if let itemsPerPage = itemsPerPage {
                parameters["per_page"] = itemsPerPage
            }
            if let nameQuery = nameQuery {
                parameters["beer_name"] = nameQuery
            }
            if let ids = ids {
                parameters["ids"] = ids.map({ String($0) }).joined(separator: "|")
            }
            return HTTPRequest(
                url: url,
                parameters: HTTPRequestParameters(parameters))

        }

    }

}
