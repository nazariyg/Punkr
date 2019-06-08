// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import Core
import Cartography
import Kingfisher

final class BeerDetailBeerImageCell: UITableViewCell {

    private static let height = s(400)
    private static let imageHorizontalPadding = s(32)
    private static let imageVerticalPadding = s(16)

    private var beerImageView: UIImageView!

    private typealias `Self` = BeerDetailBeerImageCell

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
        beerImageView = UIImageView()
        with(beerImageView!) {
            $0.contentMode = .scaleAspectFit
            contentView.addSubview($0)
        }
        beerImageView.kf.indicatorType = .activity
        (beerImageView.kf.indicator?.view as? UIActivityIndicatorView)?.color = .white
    }

    private func layout() {
        constrain(beerImageView, contentView) { view, superview in
            view.edges == inset(superview.edges, Self.imageHorizontalPadding, Self.imageVerticalPadding)
            view.height == Self.height - 2*Self.imageVerticalPadding
        }
    }

    func update(imageURL: URL?) {
        beerImageView.kf.setImage(
            with: imageURL,
            placeholder: R.image.browserListBeerImagePlaceholder(),
            options: [
                .transition(.fade(0.5))
            ])
    }

}
