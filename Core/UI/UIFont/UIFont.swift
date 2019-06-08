// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones

public extension UIFont {

    // MARK: - Main font

    static func main(_ size: CGFloat) -> UIFont {
        return .system(size)
    }

    static func mainBold(_ size: CGFloat) -> UIFont {
        return .systemBold(size)
    }

    static func mainMedium(_ size: CGFloat) -> UIFont {
        return .systemMedium(size)
    }

    static func mainLight(_ size: CGFloat) -> UIFont {
        return .systemLight(size)
    }

    static func mainItalic(_ size: CGFloat) -> UIFont {
        return .systemItalic(size)
    }

    static func mainStyle(_ style: UIFont.TextStyle) -> UIFont {
        return .systemStyle(style)
    }

    // MARK: - System font

    static func system(_ size: CGFloat) -> UIFont {
        return systemFont(ofSize: screenify(size))
    }

    static func systemBold(_ size: CGFloat) -> UIFont {
        return boldSystemFont(ofSize: screenify(size))
    }

    static func systemMedium(_ size: CGFloat) -> UIFont {
        return systemWeight(size: size, weight: .medium)
    }

    static func systemLight(_ size: CGFloat) -> UIFont {
        return systemWeight(size: size, weight: .light)
    }

    static func systemItalic(_ size: CGFloat) -> UIFont {
        return italicSystemFont(ofSize: screenify(size))
    }

    static func systemWeight(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return systemFont(ofSize: screenify(size), weight: weight)
    }

    static func systemMonospacedDigit(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return monospacedDigitSystemFont(ofSize: screenify(size), weight: weight)
    }

    static func systemStyle(_ style: UIFont.TextStyle) -> UIFont {
        // `preferredFont` scales the size of the returned font depending on the device model and screen size.
        return preferredFont(forTextStyle: style)
    }

    // MARK: - Font listing

    static func printAvailableFontNames() {
        familyNames.forEach { fontNames(forFamilyName: $0).forEach { print($0) } }
    }

}
