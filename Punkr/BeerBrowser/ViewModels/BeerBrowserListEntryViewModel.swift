// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Core

struct BeerBrowserListEntryViewModel {

    let id: Int
    let name: String
    let description: String
    let imageURL: URL?

    init(beer: Beer) {
        id = beer.id
        name = beer.name
        description = beer.description
        imageURL = beer.imageURLString.flatMap { URL(string: $0) }
    }

}
