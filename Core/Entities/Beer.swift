// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation

public struct Beer: Codable {

    public let id: Int
    public let name: String
    public let description: String
    public let imageURLString: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageURLString = "image_url"
    }

    public init(
        id: Int,
        name: String,
        description: String,
        imageURLString: String?) {

        self.id = id
        self.name = name
        self.description = description
        self.imageURLString = imageURLString
    }

}
