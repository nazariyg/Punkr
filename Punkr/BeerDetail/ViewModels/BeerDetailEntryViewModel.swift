// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation

enum BeerDetailEntryViewModel {

    case image(imageURL: URL?)
    case name(String)
    case description(String)

    init(imageURLString: String?) {
        let imageURL = imageURLString.flatMap { URL(string: $0) }
        self = .image(imageURL: imageURL)
    }

    init(name: String) {
        self = .name(name)
    }

    init(description: String) {
        self = .description(description)
    }

}
