// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import Core
import Cartography
import ReactiveSwift
import Result

final class BeerBrowserListLoadingIndicatorCell: UITableViewCell {

    private var loadingIndicator: UIActivityIndicatorView!
    private var loadingIndicationObserverDisposable: Disposable?

    // MARK: - Lifecycle

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .darkGray
        contentView.backgroundColor = .darkGray
        selectionStyle = .none

        fill()
        layout()
    }

    // MARK: - Content

    private func fill() {
        loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
        with(loadingIndicator!) {
            $0.alpha = 0
            let scale: CGFloat = 1
            $0.transform = CGAffineTransform(scaleX: scale, y: scale)
            contentView.addSubview($0)
        }
    }

    private func layout() {
        let loadingIndicatorVerticalMargin = s(16)
        constrain(loadingIndicator, contentView) { view, superview in
            view.top == superview.top + loadingIndicatorVerticalMargin
            view.bottom == superview.bottom - loadingIndicatorVerticalMargin
            view.centerX == superview.centerX
        }
    }

    func update(loadingIndication: SignalProducer<Bool, NoError>) {
        loadingIndicationObserverDisposable?.dispose()
        loadingIndicationObserverDisposable =
            loadingIndication
                .skipRepeats()
                .startWithValues { [weak self] isLoading in
                    guard let strongSelf = self else { return }
                    if isLoading {
                        strongSelf.showLoadingIndicator()
                    } else {
                        strongSelf.hideLoadingIndicator()
                    }
                }
    }

    // MARK: - Loading indicator

    private func showLoadingIndicator() {
        loadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingIndicator.alpha = 0.5
        }
    }

    private func hideLoadingIndicator() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingIndicator.alpha = 0
        }, completion: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.loadingIndicator.stopAnimating()
        })
    }

}
