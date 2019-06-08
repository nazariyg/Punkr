// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import ReactiveSwift
import Cartography
import Result

// MARK: - Protocol

public protocol UINotificationServiceProtocol: class {
    func flash(message: String)
    func flash(message: String, type: UINotificationService.NotificationType)
    func pin(message: String)
    func pin(message: String, type: UINotificationService.NotificationType)
}

// MARK: - Implementation

public final class UINotificationService: UINotificationServiceProtocol, SharedInstance {

    public typealias InstanceProtocol = UINotificationServiceProtocol
    public static let defaultInstance: InstanceProtocol = UINotificationService()

    public enum NotificationType {
        case `default`
        case error
        case success
    }

    public enum NotificationDisplayStrategy {
        case lastRequested
    }

    private enum Notification {
        case flash(message: String, type: NotificationType)
        case pinned(message: String, type: NotificationType)
    }

    public var notificationDisplayStrategy: NotificationDisplayStrategy = .lastRequested

    private static let messageFontSize: CGFloat = 19
    private static let flashNotificationMinDisplayTime: TimeInterval = 4.2
    private static let showAnimationDuration: TimeInterval = 0.33
    private static let hideAnimationDuration: TimeInterval = 0.25
    private static let flashNotificationMessageLengthToDisplayTimeFactor: Double = 0.05
    private static let notificationViewPadding: CGFloat = s(20)
    private static let messageLabelPadding: CGFloat = s(20)
    private static let notificationViewCornerRadius: CGFloat = s(12)
    private static let closeButtonSide: CGFloat = s(24)
    private static let closeButtonMargin: CGFloat = s(8)
    private static let closeButtonEffectiveMarginFactor: CGFloat = 1.5
    private static let notificationNormalBackground = UIColor("#404040")
    private static let notificationErrorBackground = Config.shared.appearance.defaultErrorBackgroundColor
    private static let notificationSuccessBackground = Config.shared.appearance.defaultSuccessBackgroundColor
    private static let notificationHasShadow = true
    private static let notificationShadowSize: CGFloat = 16
    private static let notificationShadowOpacity: CGFloat = 0.15
    private static let allowNotificationDismissalBySliding = true
    private static let slidingDismissalAccelerationFactor: CGFloat = 0.05
    private static let allowFlashNotificationDismissalByTapping = true

    private var requestedNotifications: [Notification] = []
    private var isShowingNotification = false
    private var isNotificationSlidingEnabled = false
    private var notificationSlidingYLimit: CGFloat!

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Requesting notifications

    public func flash(message: String) {
        flash(message: message, type: .default)
    }

    public func flash(message: String, type: NotificationType) {
        DispatchQueue.main.executeAsync { [weak self] in
            guard let strongSelf = self else { return }
            let flashMessage: Notification = .flash(message: message, type: type)
            strongSelf.requestedNotifications.append(flashMessage)
            strongSelf.considerShowingNotification()
        }
    }

    public func pin(message: String) {
        pin(message: message, type: .default)
    }

    public func pin(message: String, type: NotificationType) {
        DispatchQueue.main.executeAsync { [weak self] in
            guard let strongSelf = self else { return }
            let pinnedMessage: Notification = .pinned(message: message, type: type)
            strongSelf.requestedNotifications.append(pinnedMessage)
            strongSelf.considerShowingNotification()
        }
    }

    // MARK: - Private

    private func considerShowingNotification() {
        guard requestedNotifications.isNotEmpty else { return }
        switch notificationDisplayStrategy {
        case .lastRequested:
            guard !isShowingNotification else { return }
            showLastRequestedNotification()
            requestedNotifications.removeAll()
        }
    }

    private func showLastRequestedNotification() {
        guard let notification = requestedNotifications.last else { return }
        showNotification(notification)
    }

    private func showNotification(_ notification: Notification) {
        let notificationMessage: String
        let hasCloseButton: Bool
        let notificationType: NotificationType
        switch notification {
        case let .flash(message, type):
            notificationMessage = message
            notificationType = type
            hasCloseButton = false
        case let .pinned(message, type):
            notificationMessage = message
            notificationType = type
            hasCloseButton = true
        }

        let containerView: UIView =
            UIRootViewControllerContainer.shared.containerView(forKey: fullStringType(UINotificationService.self), isUserInteractionEnabled: true)

        // Notification components.

        let notificationView = NotificationView()
        with(notificationView) {
            switch notificationType {
            case .default:
                $0.backgroundColor = Self.notificationNormalBackground
            case .error:
                $0.backgroundColor = Self.notificationErrorBackground
            case .success:
                $0.backgroundColor = Self.notificationSuccessBackground
            }

            $0.roundCorners(radius: Self.notificationViewCornerRadius)
            containerView.addSubview($0)
        }

        let notificationShadowView = UIView()
        with(notificationShadowView) {
            if Self.notificationHasShadow {
                $0.backgroundColor = .black
                $0.layer.cornerRadius = Self.notificationViewCornerRadius*1.15
                $0.setShadow(ofSize: Self.notificationShadowSize, opacity: Self.notificationShadowOpacity)
            } else {
                $0.isHidden = true
            }
            containerView.insertSubview($0, belowSubview: notificationView)
        }

        let messageLabel = UIStyledLabel()
        with(messageLabel) {
            $0.numberOfLines = 0
            $0.text = notificationMessage
            $0.font = .main(Self.messageFontSize)
            $0.textAlignment = .center
            notificationView.addSubview($0)
        }

        let closeButton = UIExtraHitMarginButton()
        if hasCloseButton {
            with(closeButton) {
                $0.setImage(R.image.close(), for: .normal)
                $0.tintColor = Config.shared.appearance.defaultLineColor
                $0.extraHitMargin = s(12)
                notificationView.addSubview($0)
            }
        }

        // Layout.

        let closeButtonExtraPadding = !hasCloseButton ? 0 : Self.closeButtonSide - Self.closeButtonMargin*Self.closeButtonEffectiveMarginFactor
        constrain(messageLabel, notificationView) { view, superview in
            view.leading == superview.leading + Self.messageLabelPadding
            view.trailing == superview.trailing - Self.messageLabelPadding - closeButtonExtraPadding
            superview.top == view.top - Self.messageLabelPadding - closeButtonExtraPadding
            superview.bottom == view.bottom + Self.messageLabelPadding
        }

        constrain(notificationView, containerView) { view, superview in
            view.leading == superview.leading + Self.notificationViewPadding
            view.trailing == superview.trailing - Self.notificationViewPadding
        }

        var slidingConstraintGroup =
            constrain(notificationView, containerView) { view, superview in
                view.top == superview.bottom
            }

        constrain(notificationShadowView, notificationView) { view, reference in
            view.edges == reference.edges
        }

        if hasCloseButton {
            constrain(closeButton, notificationView) { view, superview in
                view.top == superview.top + Self.closeButtonMargin
                view.trailing == superview.trailing - Self.closeButtonMargin
                view.height == Self.closeButtonSide
                view.width == view.height
            }
        }

        // Animation.

        isShowingNotification = true

        var hideNotification: ((_ acceleration: CGFloat) -> Void)!
        var delayedHideNotificationDisposable: Disposable?

        let showNotification = {
            slidingConstraintGroup = constrain(notificationView, containerView, replace: slidingConstraintGroup) { view, superview in
                view.bottom == superview.safeAreaLayoutGuide.bottom - Self.notificationViewPadding
            }

            UIView.animate(withDuration: Self.hideAnimationDuration, delay: 0, options: .curveEaseOut, animations: {
                containerView.layoutIfNeeded()
            }, completion: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.isNotificationSlidingEnabled = true
                strongSelf.notificationSlidingYLimit = notificationView.frame.origin.y

                if case .flash = notification {
                    let displayTime = strongSelf.displayTime(forFlashNotificationMessage: notificationMessage)
                    delayedHideNotificationDisposable =
                        SignalProducer<Void, NoError>.empty
                        .delay(displayTime, on: QueueScheduler.main)
                        .startWithCompleted {
                            hideNotification(0)
                        }
                }
            })
        }

        hideNotification = { [weak self] (acceleration: CGFloat) in
            guard let strongSelf = self else { return }
            constrain(notificationView, containerView, replace: slidingConstraintGroup) { view, superview in
                view.top == superview.bottom + acceleration*Self.slidingDismissalAccelerationFactor
            }
            strongSelf.isNotificationSlidingEnabled = false

            let options: UIView.AnimationOptions = acceleration == 0 ? .curveEaseIn : .curveEaseOut

            UIView.animate(withDuration: Self.hideAnimationDuration, delay: 0, options: options, animations: {
                containerView.layoutIfNeeded()
            }, completion: { [weak self] _ in
                guard let strongSelf = self else { return }
                notificationView.removeFromSuperview()
                notificationShadowView.removeFromSuperview()
                strongSelf.isShowingNotification = false

                strongSelf.considerShowingNotification()
            })
        }

        // Control events.

        notificationView.postLayoutSubviewsAction = {
            DispatchQueue.main.executeAsync {
                showNotification()
            }
        }

        if hasCloseButton {
            closeButton.reactive.controlEvents(.touchUpInside)
                .observeValues { _ in
                    hideNotification(0)
                }
        }

        // Manual notification sliding and dismissal.

        if Self.allowNotificationDismissalBySliding {
            let slideGestureRecognizer = UIPanGestureRecognizer()
            notificationView.addGestureRecognizer(slideGestureRecognizer)
            var slidingStartTime: TimeInterval?

            slideGestureRecognizer.reactive.stateChanged
                .observeValues { [weak self] gestureRecognizer in
                    guard let strongSelf = self else { return }
                    guard strongSelf.isNotificationSlidingEnabled else { return }

                    if gestureRecognizer.state == .began {
                        delayedHideNotificationDisposable?.dispose()
                        slidingStartTime = CFAbsoluteTimeGetCurrent()

                    } else if gestureRecognizer.state == .changed {
                        delayedHideNotificationDisposable?.dispose()
                        let translation = gestureRecognizer.translation(in: notificationView.superview)
                        let y = max(notificationView.frame.origin.y + translation.y, strongSelf.notificationSlidingYLimit)
                        notificationView.frame.origin = CGPoint(x: notificationView.frame.origin.x, y: y)
                        notificationShadowView.frame.origin = notificationView.frame.origin
                        gestureRecognizer.setTranslation(.zero, in: notificationView.superview)

                    } else if gestureRecognizer.state == .ended ||
                              gestureRecognizer.state == .cancelled {

                        delayedHideNotificationDisposable?.dispose()

                        if notificationView.frame.origin.y > strongSelf.notificationSlidingYLimit {
                            // Force hide the notification.
                            let slidingEndTime = CFAbsoluteTimeGetCurrent()
                            let timeDiff = slidingEndTime - (slidingStartTime ?? slidingEndTime)
                            let absDistance = abs(notificationView.frame.origin.y - strongSelf.notificationSlidingYLimit)
                            if timeDiff != 0 {
                                let acceleration = absDistance/CGFloat(timeDiff)
                                hideNotification(acceleration)
                            } else {
                                hideNotification(0)
                            }
                        } else {
                            if case .flash = notification {
                                // Renew the display time for the flash notification.
                                let displayTime = strongSelf.displayTime(forFlashNotificationMessage: notificationMessage)
                                delayedHideNotificationDisposable =
                                    SignalProducer<Void, NoError>.empty
                                        .delay(displayTime, on: QueueScheduler.main)
                                        .startWithCompleted {
                                            hideNotification(0)
                                        }
                            }
                        }
                    }
                }
        }

        // Manual notification dismissal by a tap.

        if case .flash = notification,
           Self.allowFlashNotificationDismissalByTapping {

            let tapGestureRecognizer = UITapGestureRecognizer()
            notificationView.addGestureRecognizer(tapGestureRecognizer)

            tapGestureRecognizer.reactive.stateChanged
                .observeValues { gestureRecognizer in
                    if gestureRecognizer.state == .recognized {
                        delayedHideNotificationDisposable?.dispose()
                        hideNotification(0)
                    }
                }
        }
    }

    private func displayTime(forFlashNotificationMessage message: String) -> TimeInterval {
        // Factor in the length of the notification's message.
        let projectedDisplayTime = TimeInterval(message.count)*Self.flashNotificationMessageLengthToDisplayTimeFactor
        let displayTime = max(projectedDisplayTime, Self.flashNotificationMinDisplayTime)
        return displayTime
    }

    private typealias `Self` = UINotificationService

}

private final class NotificationView: UIView {

    var postLayoutSubviewsAction: VoidClosure?

    override func layoutSubviews() {
        super.layoutSubviews()
        postLayoutSubviewsAction?()
        postLayoutSubviewsAction = nil
    }

}
