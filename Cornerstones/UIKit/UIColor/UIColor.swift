// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit

public extension UIColor {

    /// Constructs UIColor instances from a hex strings like "rrggbb", "#rrggbb", "rrggbbaa", "#rrggbbaa".
    convenience init(_ hex: String) {
        var hex = hex.trimmed()
        hex = hex.replacingOccurrences(of: "^#", with: "", options: .regularExpression)

        assert(hex.count/2 == 3 || hex.count/2 == 4, "The hex string must contain either 3 or 4 components")

        let hasAlpha = hex.count/2 > 3
        var intHex = UInt(hex, radix: 16)!
        if !hasAlpha {
            self.init(intHex: intHex)
        } else {
            let alpha = intHex & 0xff
            intHex >>= 8
            self.init(intHex: intHex, alpha: alpha)
        }
    }

    convenience init(red: UInt, green: UInt, blue: UInt, alpha: CGFloat = 1.0) {
        assert(Range(0...255).contains(red), "Component is out of bounds")
        assert(Range(0...255).contains(green), "Component is out of bounds")
        assert(Range(0...255).contains(blue), "Component is out of bounds")

        self.init(
            red: CGFloat(red)/255,
            green: CGFloat(green)/255,
            blue: CGFloat(blue)/255,
            alpha: alpha)
    }

    convenience init(red: UInt, green: UInt, blue: UInt, alpha: UInt) {
        assert(Range(0...255).contains(red), "Component is out of bounds")
        assert(Range(0...255).contains(green), "Component is out of bounds")
        assert(Range(0...255).contains(blue), "Component is out of bounds")
        assert(Range(0...255).contains(alpha), "Component is out of bounds")

        self.init(
            red: CGFloat(red)/255,
            green: CGFloat(green)/255,
            blue: CGFloat(blue)/255,
            alpha: CGFloat(alpha)/255)
    }

    convenience init(intHex: UInt, alpha: CGFloat = 1.0) {
        assert(Range(0...0xffffff).contains(intHex), "The input is out of bounds")

        self.init(
            red: (intHex >> 16) & 0xff,
            green: (intHex >> 8) & 0xff,
            blue: intHex & 0xff,
            alpha: alpha
        )
    }

    convenience init(intHex: UInt, alpha: UInt) {
        assert(Range(0...0xffffff).contains(intHex), "The input is out of bounds")

        self.init(
            red: (intHex >> 16) & 0xff,
            green: (intHex >> 8) & 0xff,
            blue: intHex & 0xff,
            alpha: alpha
        )
    }

    var red: CGFloat {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            return fRed
        } else {
            return 0
        }
    }

    var green: CGFloat {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            return fGreen
        } else {
            return 0
        }
    }

    var blue: CGFloat {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            return fBlue
        } else {
            return 0
        }
    }

    var alpha: CGFloat {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            return fAlpha
        } else {
            return 0
        }
    }

    var intRed: UInt {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let red = UInt(round(fRed*255))
            return red
        } else {
            return 0
        }
    }

    var intGreen: UInt {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let green = UInt(round(fGreen*255))
            return green
        } else {
            return 0
        }
    }

    var intBlue: UInt {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let blue = UInt(round(fBlue*255))
            return blue
        } else {
            return 0
        }
    }

    var intAlpha: UInt {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let alpha = UInt(round(fAlpha*255))
            return alpha
        } else {
            return 0
        }
    }

    func brighter(by delta: CGFloat) -> UIColor {
        var fHue: CGFloat = 0
        var fSaturation: CGFloat = 0
        var fBrightness: CGFloat = 0
        var fAlpha: CGFloat = 0
        getHue(&fHue, saturation: &fSaturation, brightness: &fBrightness, alpha: &fAlpha)
        fBrightness = min(fBrightness + delta, 1)
        return UIColor(hue: fHue, saturation: fSaturation, brightness: fBrightness, alpha: fAlpha)
    }

    func darker(by delta: CGFloat) -> UIColor {
        var fHue: CGFloat = 0
        var fSaturation: CGFloat = 0
        var fBrightness: CGFloat = 0
        var fAlpha: CGFloat = 0
        getHue(&fHue, saturation: &fSaturation, brightness: &fBrightness, alpha: &fAlpha)
        fBrightness = max(fBrightness - delta, 0)
        return UIColor(hue: fHue, saturation: fSaturation, brightness: fBrightness, alpha: fAlpha)
    }

    static func midcolor(first: UIColor, second: UIColor) -> UIColor {
        return
            UIColor(
                red: (first.red + second.red)/2,
                green: (first.green + second.green)/2,
                blue: (first.blue + second.blue)/2,
                alpha: (first.alpha + second.alpha)/2)
    }

}
