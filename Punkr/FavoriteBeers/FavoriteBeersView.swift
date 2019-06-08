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

protocol FavoriteBeersViewProtocol {
    func wireIn(interactor: FavoriteBeersInteractorProtocol, presenter: FavoriteBeersPresenterProtocol)
    var eventSignal: Signal<FavoriteBeersView.Event, NoError> { get }
}

// MARK: - Implementation

final class FavoriteBeersView: UIViewControllerBase, FavoriteBeersViewProtocol, EventEmitter {

    enum Event {
        case selectedBeer(id: Int)
        case removedBeer(id: Int)
    }

    private var loadingIndicator: UIActivityIndicatorView!
    private var emptyListLabel: UIStyledLabel!
    private var listTableView: UIStyledTableView!
    private var beerViewModels: [FavoriteBeersListEntryViewModel] = []
    private let listTableViewIsScrolling = MutableProperty<Bool>(false)
    private var populateListDisposable: Disposable?

    // MARK: - Lifecycle

    override func initialize() {
        view.backgroundColor = Config.shared.appearance.defaultBackgroundColor
        contentTone = .dark
        scrollsByKeyboard = false

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
            let insets = UIEdgeInsets(top: view.safeAreaInsets.top, left: 0, bottom: tabBarHeight, right: 0)
            listTableView.contentInset = insets
            listTableView.scrollIndicatorInsets = insets
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listTableViewIsScrolling.value = false
    }

    // MARK: - Content

    private func fill() {
        listTableView = UIStyledTableView()
        with(listTableView!) {
            $0.registerCell(FavoriteBeersListItemCell.self)
            $0.rowHeight = s(80)
            $0.dataSource = self
            $0.delegate = self
            $0.separatorStyle = .none
            contentView.addSubview($0)
        }
        reactive.viewDidAppear
            .skipRepeats { _, _ in true }
            .observeValues { [weak self] _ in
                guard let strongSelf = self else { return }
                let initialOffset = CGPoint(x: 0, y: -strongSelf.listTableView.contentInset.top)
                strongSelf.listTableView.setContentOffset(initialOffset, animated: false)
            }

        loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
        with(loadingIndicator!) {
            $0.alpha = 0
            let scale: CGFloat = 1.5
            $0.transform = CGAffineTransform(scaleX: scale, y: scale)
            contentView.addSubview($0)
        }

        emptyListLabel = UIStyledLabel()
        with(emptyListLabel!) {
            $0.text = "favorite_beers_empty_list_label".localized
            $0.font = .main(32)
            $0.textColor = .gray
            $0.alpha = 0
            contentView.addSubview($0)
        }
    }

    private func layout() {
        constrain(listTableView, contentView) { view, superview in
            view.edges == superview.edges
        }

        constrain(loadingIndicator, contentView) { view, superview in
            view.center == superview.center
        }

        constrain(emptyListLabel, contentView) { view, superview in
            view.center == superview.center
        }
    }

    // MARK: - Requests

    func wireIn(interactor: FavoriteBeersInteractorProtocol, presenter: FavoriteBeersPresenterProtocol) {
        presenter.requestSignal
            .observe(on: UIScheduler())
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case .showLoadingIndicator:
                    strongSelf.showLoadingIndicator()
                case .hideLoadingIndicator:
                    strongSelf.hideLoadingIndicator()
                case let .populateList(beerViewModels, supplementary):
                    strongSelf.populateList(beerViewModels: beerViewModels, supplementary: supplementary)
                }
            }
    }

    // Updating

    private func rowsCount() -> Int {
        return beerViewModels.count
    }

    private func populateList(beerViewModels: [FavoriteBeersListEntryViewModel], supplementary: Bool) {
        populateListDisposable?.dispose()
        populateListDisposable =
            listTableViewIsScrolling.producer
                .filter { !$0 }
                .skipRepeats()
                .startWithValues { [weak self] _ in
                    guard let strongSelf = self else { return }
                    strongSelf.updateContent(beerViewModels: beerViewModels, supplementary: supplementary)
                }
    }

    private func updateContent(beerViewModels: [FavoriteBeersListEntryViewModel], supplementary: Bool) {
        self.beerViewModels = beerViewModels
        listTableView.reloadData()

        let currentRowCount = rowsCount()
        if supplementary && currentRowCount > 0 {
            let lastRowIndexPath = IndexPath(row: currentRowCount - 1, section: 0)
            listTableView.scrollToRow(at: lastRowIndexPath, at: .bottom, animated: true)
        }

        handleEmptyListLabel()
    }

    private func handleEmptyListLabel() {
        if beerViewModels.isEmpty {
            showEmptyListLabel()
        } else {
            hideEmptyListLabel()
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

    private func showEmptyListLabel() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.emptyListLabel.alpha = 1
        }
    }

    private func hideEmptyListLabel() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.emptyListLabel.alpha = 0
        }
    }

}

extension FavoriteBeersView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowsCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let beerViewModel = beerViewModels[indexPath.row]
        let cell = listTableView.dequeueCell(FavoriteBeersListItemCell.self, forIndexPath: indexPath)
        cell.update(beerViewModel: beerViewModel, hasSeparator: indexPath.row != 0)
        return cell
    }

}

extension FavoriteBeersView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = beerViewModels[indexPath.row].id
        eventEmitter.send(value: .selectedBeer(id: id))
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        listTableViewIsScrolling.value = true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        listTableViewIsScrolling.value = false
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let removedBeerViewModel = beerViewModels[indexPath.row]
            beerViewModels.remove(at: indexPath.row)
            listTableView.deleteRows(at: [indexPath], with: .automatic)
            eventEmitter.send(value: .removedBeer(id: removedBeerViewModel.id))
            handleEmptyListLabel()
        }
    }

}

private final class UIStyledSearchBar: UISearchBar {}
