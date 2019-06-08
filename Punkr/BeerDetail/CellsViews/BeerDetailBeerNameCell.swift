// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import Core
import Cartography
import Kingfisher

final class BeerDetailBeerNameCell: UITableViewCell {

    private static let textHorizontalPadding = s(32)
    private static let textVerticalPadding = s(16)

    private var beerNameLabel: UIStyledLabel!

    private typealias `Self` = BeerDetailBeerNameCell

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

        fill()
        layout()
    }

    // MARK: - Content

    private func fill() {
        beerNameLabel = UIStyledLabel()
        with(beerNameLabel!) {
            $0.font = .mainBold(24)
            $0.textColor = .white
            $0.textAlignment = .center
            $0.numberOfLines = 0
            contentView.addSubview($0)
        }
    }

    private func layout() {
        constrain(beerNameLabel, contentView) { view, superview in
            view.edges == inset(superview.edges, Self.textHorizontalPadding, Self.textVerticalPadding)
        }
    }

    func update(beerName: String) {
        beerNameLabel.text = beerName
    }

}
