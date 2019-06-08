// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit

public final class UILinkedViewPropertyAnimator: UIViewPropertyAnimator {

    private class LinkedAnimator {

        weak var animator: UIViewPropertyAnimator?
        var isReversed: Bool
        let progressFactor: CGFloat
        let progressExponent: CGFloat
        let maxFramesPerSecond: TimeInterval
        var lastDisplayedFrameTimestamp: CFTimeInterval?

        init(animator: UIViewPropertyAnimator?, isReversed: Bool, progressFactor: CGFloat, progressExponent: CGFloat, maxFramesPerSecond: TimeInterval) {
            self.animator = animator
            self.isReversed = isReversed
            self.progressFactor = progressFactor
            self.progressExponent = progressExponent
            self.maxFramesPerSecond = maxFramesPerSecond
        }
    }

    private var linkedAnimators: [LinkedAnimator] = []
    private var displayLink: CADisplayLink?

    public func addLinkedAnimator(
        animator: UIViewPropertyAnimator, isReversed: Bool = false, progressFactor: CGFloat = 1, progressExponent: CGFloat = 1,
        maxFramesPerSecond: TimeInterval = 60) {

        let linkedAnimator =
            LinkedAnimator(
                animator: animator, isReversed: isReversed, progressFactor: progressFactor, progressExponent: progressExponent,
                maxFramesPerSecond: maxFramesPerSecond)
        linkedAnimators.append(linkedAnimator)
    }

    public override func startAnimation() {
        super.startAnimation()
        start()
    }

    public func start() {
        createDisplayLink()
    }

    public func finish() {
        removeDisplayLink()
    }

    private func createDisplayLink() {
        let displayLink = CADisplayLink(target: self, selector: #selector(displayLinkStep))
        displayLink.add(to: .current, forMode: .common)
        self.displayLink = displayLink
    }

    private func removeDisplayLink() {
        displayLink?.remove(from: .current, forMode: .common)
    }

    @objc private func displayLinkStep(displayLink: CADisplayLink) {
        updateLinkedAnimatorsIfNeeded(displayLink.timestamp)
    }

    private func updateLinkedAnimatorsIfNeeded(_ timestamp: CFTimeInterval) {
        linkedAnimators.forEach { linkedAnimator in
            if let lastDisplayedFrameTimestamp = linkedAnimator.lastDisplayedFrameTimestamp {
                let previousFrameTimeDiff = timestamp - lastDisplayedFrameTimestamp
                let inverseFPS: CFTimeInterval = 1/linkedAnimator.maxFramesPerSecond
                guard previousFrameTimeDiff >= inverseFPS else { return }
            }

            var progress = !linkedAnimator.isReversed ? fractionComplete : 1 - fractionComplete
            progress = pow(progress, linkedAnimator.progressExponent)
            progress = progress*linkedAnimator.progressFactor
            linkedAnimator.animator?.fractionComplete = progress

            linkedAnimator.lastDisplayedFrameTimestamp = timestamp
        }
    }

    public override var isReversed: Bool {
        didSet {
            let newValue = isReversed
            if newValue != oldValue {
                linkedAnimators.forEach { linkedAnimator in
                    linkedAnimator.isReversed = !linkedAnimator.isReversed
                }
            }
        }
    }

}
