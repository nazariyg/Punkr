// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import Core
import ReactiveSwift
import Result
import ReactiveCocoa
import Cartography

// MARK: - Protocol

protocol RandomBeerViewProtocol {
    func wireIn(interactor: RandomBeerInteractorProtocol, presenter: RandomBeerPresenterProtocol)
    var eventSignal: Signal<RandomBeerView.Event, NoError> { get }
}

// MARK: - Implementation

final class RandomBeerView: UIViewControllerBase, RandomBeerViewProtocol, EventEmitter {

    enum Event {
        case tappedRandomButton
    }

    private var loadingIndicator: UIActivityIndicatorView!
    private var randomButton: UITextRoundedButton!
    private var randomButtonBottomConstraint: NSLayoutConstraint!
    private var separatorView: UIView!
    private var beerDetailContainerView: UIView!
    private let viewDidInitiallyLayoutSubviews = MutableProperty<Bool>(false)
    private var currentDetailScene: UIScene?

    private static let randomButtonVerticalPadding = s(16)
    private static let separatorHorizontalPadding = s(16)

    private typealias `Self` = RandomBeerView

    // MARK: - Lifecycle

    override func initialize() {
        view.backgroundColor = Config.shared.appearance.defaultBackgroundColor
        contentTone = .dark

        fill()
        layout()
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let tabBarHeight = (tabBarController as? UIHomeScreenTabsController)?.tabBarHeight {
            randomButtonBottomConstraint.constant = -(tabBarHeight + Self.randomButtonVerticalPadding)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewDidInitiallyLayoutSubviews.value = true
    }

    // MARK: - Content

    private func fill() {
        randomButton = UITextRoundedButton(horizontalPadding: 16, verticalPadding: 16, cornerRadius: 12, lineWidth: 3, lineColor: .gray)
        with(randomButton!) {
            $0.setTitle("random_beer_button_title".localized, for: .normal)
            $0.titleLabel?.font = .mainBold(22)
            contentView.addSubview($0)

            $0.reactive.controlEvents(.touchUpInside)
                .observeValues { [weak self] _ in
                    guard let strongSelf = self else { return }
                    strongSelf.eventEmitter.send(value: .tappedRandomButton)
                }
        }

        separatorView = UIView()
        with(separatorView!) {
            separatorView.backgroundColor = .lightGray
            contentView.addSubview($0)
        }

        beerDetailContainerView = UIView()
        with(beerDetailContainerView!) {
            contentView.addSubview($0)
        }

        loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
        with(loadingIndicator!) {
            $0.alpha = 0
            let scale: CGFloat = 1.5
            $0.transform = CGAffineTransform(scaleX: scale, y: scale)
            contentView.addSubview($0)
        }
    }

    private func layout() {
        constrain(randomButton, contentView) { view, superview in
            view.centerX == superview.centerX
            randomButtonBottomConstraint = view.bottom == superview.bottom
        }

        constrain(separatorView, contentView, randomButton) { view, superview, previous in
            view.leading == superview.leading + Self.separatorHorizontalPadding
            view.trailing == superview.trailing - Self.separatorHorizontalPadding
            view.bottom == previous.top - Self.randomButtonVerticalPadding
            view.height == s(2)
        }

        constrain(beerDetailContainerView, contentView, separatorView) { view, superview, previous in
            view.leading == superview.leading
            view.trailing == superview.trailing
            view.top == superview.top
            view.bottom == previous.top
        }

        constrain(loadingIndicator, contentView) { view, superview in
            view.center == superview.center
        }
    }

    // MARK: - Requests

    func wireIn(interactor: RandomBeerInteractorProtocol, presenter: RandomBeerPresenterProtocol) {
        interactor.requestSignal
            .observe(on: UIScheduler())
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case let .showContent(imageURLString, name, description):
                    strongSelf.viewDidInitiallyLayoutSubviews.producer
                        .filter { $0 }
                        .skipRepeats()
                        .startWithValues { [weak self] _ in
                            guard let strongSelf = self else { return }
                            strongSelf.updateContent(imageURLString: imageURLString, name: name, description: description)
                        }
                }
            }

        presenter.requestSignal
            .observe(on: UIScheduler())
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case .showLoadingIndicator:
                    strongSelf.showLoadingIndicator()
                case .hideLoadingIndicator:
                    strongSelf.hideLoadingIndicator()
                }
            }
    }

    // MARK: - Show/hide animations

    private func showLoadingIndicator() {
        loadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingIndicator.alpha = 0.5
        }
    }

    private func hideLoadingIndicator() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingIndicator.alpha = 0
        }, completion: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.loadingIndicator.stopAnimating()
        })
    }

    // MARK: - Content

    private func updateContent(imageURLString: String?, name: String, description: String) {
        let scene = BeerDetailScene()
        let beer = Beer(id: 0, name: name, description: description, imageURLString: imageURLString)
        let parameters = BeerDetailScene.Parameters(beer: beer, isSubview: true)
        scene.setParameters(parameters)

        let viewController = scene.viewController
        if currentDetailScene == nil {
            addChild(viewController)
            viewController.view.frame = beerDetailContainerView.bounds
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            beerDetailContainerView.addSubview(viewController.view)
            viewController.didMove(toParent: self)
        } else {
            guard let previousViewController = currentDetailScene?.viewController else { return }
            addChild(viewController)
            previousViewController.willMove(toParent: nil)
            viewController.view.frame = beerDetailContainerView.bounds
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            transition(
                from: previousViewController, to: viewController, duration: 0.5, options: .transitionCrossDissolve,
                animations: nil, completion: { [weak self] _ in
                    guard let strongSelf = self else { return }
                    previousViewController.removeFromParent()
                    viewController.didMove(toParent: strongSelf)
                })
        }

        currentDetailScene = scene
    }

}
