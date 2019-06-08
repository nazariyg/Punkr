// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones

@IBDesignable
public final class UIIconCircleButton: UIExtraHitMarginButton {

    public static let defaultIconPadding: CGFloat = 8
    public static let defaultFillColor: UIColor? = nil
    public static let defaultLineColor: UIColor? = nil
    public static let defaultLineWidth: CGFloat = 1.5
    public static let defaultIconTintColor = Config.shared.appearance.defaultForegroundColor
    public static let defaultDisabledIconTintColor = Config.shared.appearance.defaultDisabledForegroundColor
    public static let defaultDisabledFillColor = Config.shared.appearance.defaultDisabledBackgroundColor
    public static let defaultDisabledLineColor = Config.shared.appearance.defaultDisabledForegroundColor

    @IBInspectable fileprivate var iconPadding: CGFloat = defaultIconPadding
    @IBInspectable fileprivate var fillColor: UIColor? = defaultFillColor
    @IBInspectable fileprivate var lineColor: UIColor? = defaultLineColor
    @IBInspectable fileprivate var lineWidth: CGFloat = defaultLineWidth
    @IBInspectable fileprivate var disabledIconTintColor: UIColor = defaultDisabledIconTintColor
    @IBInspectable fileprivate var disabledFillColor: UIColor = defaultDisabledFillColor
    @IBInspectable fileprivate var disabledLineColor: UIColor = defaultDisabledLineColor

    private var circleView: UIIconCircleButtonCircleView!
    private var iconImageView: UIImageView!

    public init(
        iconPadding: CGFloat = defaultIconPadding,
        fillColor: UIColor? = defaultFillColor,
        lineColor: UIColor? = defaultLineColor,
        lineWidth: CGFloat = defaultLineWidth,
        iconTintColor: UIColor = defaultIconTintColor,
        disabledIconTintColor: UIColor = defaultDisabledIconTintColor,
        disabledFillColor: UIColor = defaultDisabledFillColor,
        disabledLineColor: UIColor = defaultDisabledLineColor) {

        self.iconPadding = screenify(iconPadding)
        self.fillColor = fillColor
        self.lineColor = lineColor
        self.lineWidth = screenify(lineWidth)
        self.iconTintColor = iconTintColor
        self.disabledIconTintColor = disabledIconTintColor
        self.disabledFillColor = disabledFillColor
        self.disabledLineColor = disabledLineColor

        super.init(frame: .zero)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        iconPadding = screenify(iconPadding)
        lineWidth = screenify(lineWidth)

        commonInit()
    }

    private func commonInit() {
        circleView = UIIconCircleButtonCircleView()
        circleView.button = self
        with(self, circleView!) {
            $1.backgroundColor = .clear
            $1.isUserInteractionEnabled = false
            $0.addSubview($1)
            $1.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $1.leadingAnchor.constraint(equalTo: $0.leadingAnchor),
                $1.trailingAnchor.constraint(equalTo: $0.trailingAnchor),
                $1.topAnchor.constraint(equalTo: $0.topAnchor),
                $1.bottomAnchor.constraint(equalTo: $0.bottomAnchor)
            ])
        }

        iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        with(self, iconImageView!) {
            $0.addSubview($1)
            $1.tintColor = iconTintColor
            $1.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $1.leadingAnchor.constraint(equalTo: $0.leadingAnchor, constant: iconPadding),
                $1.trailingAnchor.constraint(equalTo: $0.trailingAnchor, constant: -iconPadding),
                $1.topAnchor.constraint(equalTo: $0.topAnchor, constant: iconPadding),
                $1.bottomAnchor.constraint(equalTo: $0.bottomAnchor, constant: -iconPadding)
            ])
        }
    }

    public var icon: UIImage? {
        get {
            return iconImageView.image
        }
        set(icon) {
            iconImageView.image = icon
        }
    }

    @IBInspectable public var iconTintColor: UIColor = defaultIconTintColor {
        didSet {
            iconImageView.tintColor = iconTintColor
        }
    }

    public var contentTransform: CGAffineTransform = .identity {
        didSet {
            circleView.transform = contentTransform
            iconImageView.transform = contentTransform
        }
    }

    public override func layerWillDraw(_ layer: CALayer) {
        super.layerWillDraw(layer)

        if iconImageView.image?.renderingMode == .alwaysTemplate {
            if isEnabled {
                iconImageView.tintColor = iconTintColor
            } else {
                iconImageView.tintColor = disabledIconTintColor
            }
        }
    }

    public override func draw(_ rect: CGRect) {
        // Empty.
    }

}

public final class UIIconCircleButtonCircleView: UIView {

    fileprivate weak var button: UIIconCircleButton!

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let size = bounds.size

        let diameter = min(size.width, size.height)
        let circleRect = CGRect(x: (size.width - diameter)/2, y: (size.height - diameter)/2, width: diameter, height: diameter)

        if let fillColor = button.fillColor {
            let inset = button.lineWidth/2
            let fillCircleRect = circleRect.insetBy(dx: inset, dy: inset)
            let color = button.isEnabled ? fillColor : button.disabledFillColor
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: fillCircleRect)
        }

        if let lineColor = button.lineColor {
            let inset = button.lineWidth/2
            let lineCircleRect = circleRect.insetBy(dx: inset, dy: inset)
            let color = button.isEnabled ? lineColor : button.disabledLineColor
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(button.lineWidth)
            context.strokeEllipse(in: lineCircleRect)
        }
    }

}
