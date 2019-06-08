// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import ReactiveSwift

/// The base view controller to be subclassed by scene views. Supports scrolling the content by keyboard appearance, dismissing the keyboard on tap
/// within the non-control area of the content view, animated showing and hiding of the navigation bar and the status bar, tinting the status bar and
/// scroll indicators depending on the tone of the content.

open class UIViewControllerBase: UIViewController {

    public private(set) var contentView: UIView!

    public enum ContentTone {
        case light
        case dark
    }

    public var scrollsByKeyboard = true
    public var scrollingByKeyboardContentOffsetFactor: CGFloat = 0.25
    public var dismissesKeyboardOnTap = true
    public var displaysNavigationBar = false
    public var displaysStatusBar = true
    public var setsGlobalBackgroundColor = false
    public var keyboardAppearance: UIKeyboardAppearance?
    public var statusBarStyle: UIStatusBarStyle = .default
    public var keyboardScrollViewIndicatorStyle: UIScrollView.IndicatorStyle = .default
    public var contentTone: ContentTone?  // if set, overrides the style settings above
    public var statusBarUpdateAnimation: UIStatusBarAnimation = .slide
    public var interactiveDismissalEnabled = false
    public var displaysTabBar = true
    open var contentViewType: UIView.Type? { return nil }

    public let isShown = MutableProperty<Bool>(false)

    private var keyboardScrollView: UIScrollView!
    private var isCurrentlySubstitutingPrefersStatusBarHidden = false
    private static let statusBarUpdateAnimationDuration: TimeInterval = 0.33

    // MARK: - Lifecycle

    open func initialize() {
        // To be overriden by subclassing view controllers. This method is invoked at the time of view controller contruction.
        // To be used instead of `viewDidLoad`. No need to call `super`.
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        loadViewIfNeeded()

        addChrome()

        // Subclass view controller initialization.
        initialize()

        insertBackgroundColorView()

        if scrollsByKeyboard {
            subscribeToKeyboardNotifications()
            initKeyboardScrollViewIndicatorStyle()
        } else {
            keyboardScrollView.isScrollEnabled = false
        }

        if let keyboardDismissibleView = contentView as? UIKeyboardDismissibleView {
            keyboardDismissibleView.keyboardDismissingEnabled = dismissesKeyboardOnTap
        }
    }

    private func initKeyboardScrollViewIndicatorStyle() {
        if let contentTone = contentTone {
            switch contentTone {
            case .light: keyboardScrollView.indicatorStyle = .black
            case .dark: keyboardScrollView.indicatorStyle = .white
            }
        } else {
            keyboardScrollView.indicatorStyle = keyboardScrollViewIndicatorStyle
        }
    }

    private func addChrome() {
        let rootScrollView = UIScrollView()
        with(view!, rootScrollView) {
            $0.addSubview($1)
            $1.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $1.leadingAnchor.constraint(equalTo: $0.leadingAnchor),
                $1.trailingAnchor.constraint(equalTo: $0.trailingAnchor),
                $1.topAnchor.constraint(equalTo: $0.topAnchor),
                $1.bottomAnchor.constraint(equalTo: $0.bottomAnchor)
            ])
        }
        rootScrollView.contentInsetAdjustmentBehavior = .never
        self.keyboardScrollView = rootScrollView

        let contentView: UIView
        if let contentViewType = contentViewType {
            contentView = contentViewType.init()
        } else {
            contentView = UIKeyboardDismissibleView()
        }

        with(rootScrollView, contentView) {
            $0.addSubview($1)
            $1.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $1.leadingAnchor.constraint(equalTo: $0.leadingAnchor),
                $1.trailingAnchor.constraint(equalTo: $0.trailingAnchor),
                $1.topAnchor.constraint(equalTo: $0.topAnchor),
                $1.bottomAnchor.constraint(equalTo: $0.bottomAnchor),
                $1.centerXAnchor.constraint(equalTo: $0.centerXAnchor),
                $1.centerYAnchor.constraint(equalTo: $0.centerYAnchor)
            ])
        }
        self.contentView = contentView
    }

    private func insertBackgroundColorView() {
        let backgroundColorView = UIView()
        backgroundColorView.backgroundColor = contentView.backgroundColor
        with(view!, backgroundColorView) {
            $0.insertSubview($1, at: 0)
            $1.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $1.centerXAnchor.constraint(equalTo: $0.centerXAnchor),
                $1.centerYAnchor.constraint(equalTo: $0.centerYAnchor),
                $1.widthAnchor.constraint(equalTo: $0.widthAnchor),
                $1.heightAnchor.constraint(equalTo: $0.heightAnchor, multiplier: 5, constant: 0)
            ])
        }
    }

    // MARK: - Appearance

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handleNavigationBar()
        handleStatusBar()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            // Back button in the navigation bar tapped.
            UIScener.shared._goingBack(outgoingViewController: self)
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isShown.value = true
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isShown.value = false
    }

    open func handleNavigationBar() {
        navigationController?.setNavigationBarHidden(!displaysNavigationBar, animated: true)
    }

    private func handleStatusBar() {
        isCurrentlySubstitutingPrefersStatusBarHidden = true
        UIView.animate(withDuration: Self.statusBarUpdateAnimationDuration,
            animations: { [weak self] in
                self?.setNeedsStatusBarAppearanceUpdate()
            }, completion: { [weak self] _ in
                self?.isCurrentlySubstitutingPrefersStatusBarHidden = false
            })
    }

    // MARK: - Scrolling on keyboard appearance

    private func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard
            scrollsByKeyboard,
            let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let rootScrollView = keyboardScrollView,
            containsCurrentFirstResponder
        else { return }

        var extraBottomScrollInsets: CGFloat = 0
        if let window = rootScrollView.window {
            extraBottomScrollInsets = window.bounds.height - rootScrollView.frame.height

        }

        with(rootScrollView) {
            $0.contentInset.bottom = keyboardSize.height
            $0.scrollIndicatorInsets.top = rootScrollView.safeAreaInsets.top
            $0.scrollIndicatorInsets.bottom = keyboardSize.height - extraBottomScrollInsets
            $0.setContentOffset(CGPoint(x: 0, y: keyboardSize.height*scrollingByKeyboardContentOffsetFactor), animated: true)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        guard
            scrollsByKeyboard,
            let rootScrollView = keyboardScrollView,
            containsCurrentFirstResponder
        else { return }

        with(rootScrollView) {
            $0.contentInset.bottom = 0
            $0.scrollIndicatorInsets.top = 0
            $0.scrollIndicatorInsets.bottom = 0
            $0.setContentOffset(.zero, animated: true)
        }
    }

    // MARK: - UIKit

    open override var prefersStatusBarHidden: Bool {
        if !isCurrentlySubstitutingPrefersStatusBarHidden {
            return UIApplication.shared.isStatusBarHidden
        } else {
            return !displaysStatusBar
        }
    }

    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return statusBarUpdateAnimation
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if let contentTone = contentTone {
            switch contentTone {
            case .light: return .default
            case .dark: return .lightContent
            }
        } else {
            return statusBarStyle
        }
    }

    private typealias `Self` = UIViewControllerBase

}
