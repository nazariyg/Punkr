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

protocol BeerBrowserViewProtocol {
    func wireIn(interactor: BeerBrowserInteractorProtocol, presenter: BeerBrowserPresenterProtocol)
    var eventSignal: Signal<BeerBrowserView.Event, NoError> { get }
}

// MARK: - Implementation

final class BeerBrowserView: UIViewControllerBase, BeerBrowserViewProtocol, EventEmitter {

    enum Event {
        case scrolledToEnd
        case enteredSearchMode(searchText: String)
        case enteredListingMode
        case selectedBeer(id: Int)
    }

    private enum DisplayMode {
        case listing
        case searching
    }

    private var initialLoadingIndicator: UIActivityIndicatorView!
    private var noResultsLabel: UIStyledLabel!
    private var searchBar: UIStyledSearchBar!
    private var listTableView: UIStyledTableView!
    private var beerViewModels: [BeerBrowserListEntryViewModel] = []
    private let isLoadingNextPage = MutableProperty<Bool>(false)
    private var isDisplayingLastPage = false
    private let listTableViewIsScrolling = MutableProperty<Bool>(false)
    private var populateListDisposable: Disposable?
    private var hideNextPageLoadingIndicatorDisposable: Disposable?
    private var displayMode: DisplayMode = .listing

    private static let searchBarExtraHeight = s(64)

    private typealias `Self` = BeerBrowserView

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

        searchBar.searchFieldBackgroundPositionAdjustment = UIOffset(horizontal: 0, vertical: view.safeAreaInsets.top/2)

        if let tabBarHeight = (tabBarController as? UIHomeScreenTabsController)?.tabBarHeight {
            let insets = UIEdgeInsets(top: view.safeAreaInsets.top + Self.searchBarExtraHeight, left: 0, bottom: tabBarHeight, right: 0)
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
            $0.registerCell(BeerBrowserListItemCell.self)
            $0.registerCell(BeerBrowserListLoadingIndicatorCell.self)
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

        searchBar = UIStyledSearchBar()
        with(searchBar!) {
            $0.barStyle = .black
            $0.tintColor = Config.shared.appearance.defaultForegroundColor
            $0.keyboardAppearance = .dark
            $0.placeholder = "beer_browser_search_bar_placeholder_text".localized
            $0.autocapitalizationType = .none
            contentView.addSubview($0)

            $0.reactive.continuousTextValues
                .skipNil()
                .observeValues { [weak self] searchText in
                    guard let strongSelf = self else { return }
                    if searchText.isNotEmpty {
                        strongSelf.eventEmitter.send(value: .enteredSearchMode(searchText: searchText))
                        strongSelf.displayMode = .searching
                    } else {
                        strongSelf.eventEmitter.send(value: .enteredListingMode)
                        strongSelf.displayMode = .listing
                    }
                }

            $0.reactive.searchButtonClicked
                .observeValues { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.searchBar.resignFirstResponder()
                }
        }

        initialLoadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
        with(initialLoadingIndicator!) {
            $0.alpha = 0
            let scale: CGFloat = 1.5
            $0.transform = CGAffineTransform(scaleX: scale, y: scale)
            contentView.addSubview($0)
        }

        noResultsLabel = UIStyledLabel()
        with(noResultsLabel!) {
            $0.text = "beer_browser_searching_no_results_label".localized
            $0.font = .main(32)
            $0.textColor = .gray
            $0.alpha = 0
            contentView.addSubview($0)
        }

        UITextField.appearance(whenContainedInInstancesOf: [UIStyledSearchBar.self]).defaultTextAttributes =
            [.foregroundColor: Config.shared.appearance.defaultForegroundColor]
    }

    private func layout() {
        constrain(listTableView, contentView) { view, superview in
            view.edges == superview.edges
        }

        constrain(searchBar, contentView) { view, superview in
            view.top == superview.top
            view.leading == superview.leading
            view.trailing == superview.trailing
            view.bottom == superview.safeAreaLayoutGuide.top + Self.searchBarExtraHeight
        }

        constrain(initialLoadingIndicator, contentView) { view, superview in
            view.center == superview.center
        }

        constrain(noResultsLabel, contentView) { view, superview in
            view.center == superview.center
        }
    }

    // MARK: - Requests

    func wireIn(interactor: BeerBrowserInteractorProtocol, presenter: BeerBrowserPresenterProtocol) {
        interactor.requestSignal
            .observe(on: UIScheduler())
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case .clearList:
                    strongSelf.clearList()
                default: break
                }
            }

        presenter.requestSignal
            .observe(on: UIScheduler())
            .observeValues { [weak self] request in
                guard let strongSelf = self else { return }
                switch request {
                case .showInitialLoadingIndicator:
                    strongSelf.showInitialLoadingIndicator()
                    strongSelf.hideNoResultsLabel()
                case .hideInitialLoadingIndicator:
                    strongSelf.hideInitialLoadingIndicator()
                case let .populateList(beerViewModels, isLastPage):
                    strongSelf.populateList(beerViewModels: beerViewModels, isLastPage: isLastPage)
                case .showNextPageLoadingIndicator:
                    strongSelf.isLoadingNextPage.value = true
                case .hideNextPageLoadingIndicator:
                    strongSelf.hideNextPageLoadingIndicatorDisposable?.dispose()
                    strongSelf.hideNextPageLoadingIndicatorDisposable =
                        strongSelf.listTableViewIsScrolling.producer
                            .filter { !$0 }
                            .skipRepeats()
                            .startWithValues { [weak self] _ in
                                guard let strongSelf = self else { return }
                                strongSelf.isLoadingNextPage.value = false
                            }
                }
            }
    }

    // Updating

    private func rowsCount() -> Int {
        return beerViewModels.isEmpty ? 0 : beerViewModels.count + (!isDisplayingLastPage ? 1 : 0)
    }

    private func populateList(beerViewModels: [BeerBrowserListEntryViewModel], isLastPage: Bool) {
        populateListDisposable?.dispose()
        populateListDisposable =
            listTableViewIsScrolling.producer
                .filter { !$0 }
                .skipRepeats()
                .startWithValues { [weak self] _ in
                    guard let strongSelf = self else { return }
                    strongSelf.updateContent(beerViewModels: beerViewModels, isLastPage: isLastPage)
                }
    }

    private func updateContent(beerViewModels: [BeerBrowserListEntryViewModel], isLastPage: Bool) {
        let previousRowsCount = rowsCount()
        self.beerViewModels = beerViewModels
        isDisplayingLastPage = isLastPage
        let currentRowsCount = rowsCount()

        if currentRowsCount > previousRowsCount {
            let rowIndexPaths = (previousRowsCount..<currentRowsCount).map { IndexPath(row: $0, section: 0) }
            let beforePreviousLastIndexPath = [IndexPath(row: previousRowsCount - 1, section: 0)]
            listTableView.beginUpdates()
            listTableView.deleteRows(at: beforePreviousLastIndexPath, with: .fade)
            listTableView.insertRows(at: beforePreviousLastIndexPath.appending(contentsOf: rowIndexPaths), with: .bottom)
            listTableView.endUpdates()
        } else if currentRowsCount < previousRowsCount {
            let rowIndexPaths = (currentRowsCount..<previousRowsCount).map { IndexPath(row: $0, section: 0) }
            listTableView.deleteRows(at: rowIndexPaths, with: .fade)
        } else {
            listTableView.reloadData()
        }

        if displayMode == .searching && beerViewModels.isEmpty {
            showNoResultsLabel()
        } else {
            hideNoResultsLabel()
        }
    }

    private func clearList() {
        beerViewModels = []
        isDisplayingLastPage = false
        listTableView.reloadData()
    }

    // MARK: - Show/hide animations

    private func showInitialLoadingIndicator() {
        initialLoadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.initialLoadingIndicator.alpha = 0.5
        }
    }

    private func hideInitialLoadingIndicator() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.initialLoadingIndicator.alpha = 0
        }, completion: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.initialLoadingIndicator.stopAnimating()
        })
    }

    private func showNoResultsLabel() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.noResultsLabel.alpha = 1
        }
    }

    private func hideNoResultsLabel() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.noResultsLabel.alpha = 0
        }
    }

}

extension BeerBrowserView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowsCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row != self.tableView(listTableView, numberOfRowsInSection: 0) - 1 || isDisplayingLastPage {
            let beerViewModel = beerViewModels[indexPath.row]
            let cell = listTableView.dequeueCell(BeerBrowserListItemCell.self, forIndexPath: indexPath)
            cell.update(beerViewModel: beerViewModel, hasSeparator: indexPath.row != 0)
            return cell
        } else {
            let cell = listTableView.dequeueCell(BeerBrowserListLoadingIndicatorCell.self, forIndexPath: indexPath)
            cell.update(loadingIndication: isLoadingNextPage.producer)
            return cell
        }
    }

}

extension BeerBrowserView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = beerViewModels[indexPath.row].id
        eventEmitter.send(value: .selectedBeer(id: id))
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        listTableViewIsScrolling.value = true
        if searchBar.isFirstResponder {
            view.endEditing(true)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        listTableViewIsScrolling.value = false
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell is BeerBrowserListLoadingIndicatorCell {
            eventEmitter.send(value: .scrolledToEnd)
        }
    }

}

private final class UIStyledSearchBar: UISearchBar {}
