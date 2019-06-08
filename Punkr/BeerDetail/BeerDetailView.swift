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

protocol BeerDetailViewProtocol {
    func wireIn(interactor: BeerDetailInteractorProtocol, presenter: BeerDetailPresenterProtocol)
    var eventSignal: Signal<BeerDetailView.Event, NoError> { get }
}

// MARK: - Implementation

final class BeerDetailView: UIViewControllerBase, BeerDetailViewProtocol, EventEmitter {

    enum Event {
        case tappedToggleFavoriteBeer
    }

    private var entryTableView: UIStyledTableView!
    private var entryViewModels: [BeerDetailEntryViewModel] = []
    private var favoriteBeerBarItem: UIBarButtonItem?

    // MARK: - Lifecycle

    override func initialize() {
        view.backgroundColor = Config.shared.appearance.defaultBackgroundColor
        contentTone = .dark
        hidesBottomBarWhenPushed = true

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
        let insets = view.safeAreaInsets
        entryTableView.contentInset = insets
        entryTableView.scrollIndicatorInsets = insets
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationBar = navigationController?.navigationBar {
            navigationBar.barStyle = .blackTranslucent
            navigationBar.tintColor = .white
        }

        if parent === navigationController {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }

    override func handleNavigationBar() {
        // Do nothing.
    }

    private func handleSubviewAppearance(isSubview: Bool) {
        if isSubview != true {
            navigationController?.setNavigationBarHidden(false, animated: true)
            entryTableView.showsVerticalScrollIndicator = true

            let barItem = UIBarButtonItem(image: R.image.starEmpty(), style: .plain, target: self, action: #selector(tappedToggleFavoriteBeer))
            navigationItem.rightBarButtonItem = barItem
            favoriteBeerBarItem = barItem
        } else {
            navigationController?.setNavigationBarHidden(true, animated: true)
            entryTableView.showsVerticalScrollIndicator = false
        }
    }

    @objc private func tappedToggleFavoriteBeer() {
        eventEmitter.send(value: .tappedToggleFavoriteBeer)
    }

    // MARK: - Content

    private func fill() {
        entryTableView = UIStyledTableView()
        with(entryTableView!) {
            $0.registerCell(BeerDetailBeerImageCell.self)
            $0.registerCell(BeerDetailBeerNameCell.self)
            $0.registerCell(BeerDetailBeerDescriptionCell.self)
            $0.dataSource = self
            $0.allowsSelection = false
            $0.separatorStyle = .none
            contentView.addSubview($0)
        }
    }

    private func layout() {
        constrain(entryTableView, contentView) { view, superview in
            view.edges == superview.edges
        }
    }

    // MARK: - Requests

    func wireIn(interactor: BeerDetailInteractorProtocol, presenter: BeerDetailPresenterProtocol) {
        presenter.requestSignal
            .observe(on: UIScheduler())
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case let .showContent(entryViewModels, isFavorite, isSubview):
                    strongSelf.handleSubviewAppearance(isSubview: isSubview)
                    strongSelf.entryViewModels = entryViewModels
                    strongSelf.entryTableView.reloadData()

                    isFavorite
                        .observe(on: UIScheduler())
                        .startWithValues { [weak self] isFavorite in
                            guard
                                let strongSelf = self,
                                let favoriteBeerBarItem = strongSelf.favoriteBeerBarItem
                            else { return }

                            favoriteBeerBarItem.image = isFavorite ? R.image.starFilled() : R.image.starEmpty()
                        }
                }
            }
    }

}

extension BeerDetailView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entryViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entryViewModel = entryViewModels[indexPath.row]
        switch entryViewModel {

        case let .image(imageURL):
            let cell = entryTableView.dequeueCell(BeerDetailBeerImageCell.self, forIndexPath: indexPath)
            cell.update(imageURL: imageURL)
            return cell

        case let .name(name):
            let cell = entryTableView.dequeueCell(BeerDetailBeerNameCell.self, forIndexPath: indexPath)
            cell.update(beerName: name)
            return cell

        case let .description(description):
            let cell = entryTableView.dequeueCell(BeerDetailBeerDescriptionCell.self, forIndexPath: indexPath)
            cell.update(beerDescription: description)
            return cell

        }
    }

}
