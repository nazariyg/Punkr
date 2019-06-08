// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones

public extension Backend.API.V2.Beers {

    var request: HTTPRequest {

        switch self {

        case .random:
            return HTTPRequest(url: url)

        }

    }

}
