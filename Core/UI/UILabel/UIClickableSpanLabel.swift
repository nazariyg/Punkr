// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones

public final class UIClickableSpanLabel: UIStyledLabel {

    public struct ClickableSpan {

        let range: NSRange
        let action: VoidClosure

        public init(range: NSRange, action: @escaping VoidClosure) {
            self.range = range
            self.action = action
        }

    }

    public var clickableSpans: [ClickableSpan] = []
    public var showSpanFrames = false

    private static let extraHitMargin = s(10)
    private var spanViews: [UIView] = []

    // MARK: - Lifecycle

    public override init() {
        super.init()
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = true
    }

    // MARK: - Spans

    public override func layoutSubviews() {
        super.layoutSubviews()
        makeSpanViews()
    }

    private func makeSpanViews() {
        spanViews.forEach { $0.removeFromSuperview() }
        spanViews.removeAll()

        clickableSpans.forEach { span in
            guard var frame = boundingRect(forRange: span.range) else { return }
            frame = frame.insetBy(dx: -Self.extraHitMargin, dy: -Self.extraHitMargin)
            let spanView = UIView(frame: frame)
            if showSpanFrames {
                spanView.backgroundColor = UIColor.gray.withAlphaComponent(0.25)
            }

            let tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.reactive.stateChanged
                .observeValues { gestureRecognizer in
                    if gestureRecognizer.state == .recognized {
                        span.action()
                    }
                }
            spanView.addGestureRecognizer(tapGestureRecognizer)

            addSubview(spanView)
        }
    }

    private typealias `Self` = UIClickableSpanLabel

}
