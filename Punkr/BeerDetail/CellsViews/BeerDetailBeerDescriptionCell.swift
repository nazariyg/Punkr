// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import Core
import Cartography
import Kingfisher

final class BeerDetailBeerDescriptionCell: UITableViewCell {

    private static let textHorizontalPadding = s(32)
    private static let textVerticalPadding = s(16)

    private var beerDescriptionLabel: UIStyledLabel!

    private typealias `Self` = BeerDetailBeerDescriptionCell

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
        beerDescriptionLabel = UIStyledLabel()
        with(beerDescriptionLabel!) {
            $0.font = .main(18)
            $0.numberOfLines = 0
            $0.textAlignment = .justified
            contentView.addSubview($0)
        }
    }

    private func layout() {
        constrain(beerDescriptionLabel, contentView) { view, superview in
            view.edges == inset(superview.edges, Self.textHorizontalPadding, Self.textVerticalPadding)
        }
    }

    func update(beerDescription: String) {
        beerDescriptionLabel.text = beerDescription
    }

}
