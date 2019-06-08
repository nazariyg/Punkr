// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones
import Core
import Cartography
import Kingfisher

final class FavoriteBeersListItemCell: UITableViewCell {

    private var separatorView: UIImageView!
    private var beerImageView: UIImageView!
    private var beerNameLabel: UIStyledLabel!

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

        let selectedBackView = UIImageView()
        selectedBackView.image = UIImage.pixelImage(withColor: UIColor.white.withAlphaComponent(0.4))
        selectedBackgroundView = selectedBackView

        fill()
        layout()
    }

    // MARK: - Content

    private func fill() {
        separatorView = UIImageView()
        with(separatorView!) {
            $0.image = UIImage.pixelImage(withColor: .lightGray)
            contentView.addSubview($0)
        }

        beerImageView = UIImageView()
        with(beerImageView!) {
            $0.contentMode = .scaleAspectFit
            contentView.addSubview($0)
        }
        beerImageView.kf.indicatorType = .activity
        (beerImageView.kf.indicator?.view as? UIActivityIndicatorView)?.color = .white

        beerNameLabel = UIStyledLabel()
        with(beerNameLabel!) {
            $0.font = .mainMedium(22)
            $0.textAlignment = .right
            $0.numberOfLines = 0
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.5
            contentView.addSubview($0)
        }
    }

    private func layout() {
        let separatorInset = s(16)
        let separatorHeight = s(2)
        constrain(separatorView, contentView) { view, superview in
            view.height == separatorHeight
            view.leading == superview.leading + separatorInset
            view.trailing == superview.trailing - separatorInset
            view.top == superview.top
        }

        let imageViewVerticalMargin = s(12)
        let imageViewTextMargin: CGFloat = s(16)
        let textTrailingMargin = s(24)
        let textVerticalMargin = s(8)

        constrain(beerImageView, contentView) { view, superview in
            view.leading == superview.leading + s(24)
            view.top == superview.top + imageViewVerticalMargin
            view.bottom == superview.bottom - imageViewVerticalMargin
            view.width == view.height
        }

        constrain(beerNameLabel, contentView, beerImageView) { view, superview, icon in
            view.leading == icon.trailing + imageViewTextMargin
            view.trailing == superview.trailing - textTrailingMargin
            view.top == superview.top + textVerticalMargin
            view.bottom == superview.bottom - textVerticalMargin
        }
    }

    func update(beerViewModel: FavoriteBeersListEntryViewModel, hasSeparator: Bool) {
        separatorView.isHidden = !hasSeparator

        let beerImageDownsamplingReferenceSize: CGFloat = 128
        let downsamplingProcessor =
            ResizingImageProcessor(
                referenceSize: CGSize(width: beerImageDownsamplingReferenceSize, height: beerImageDownsamplingReferenceSize),
                mode: .aspectFit)
        beerImageView.kf.setImage(
            with: beerViewModel.imageURL,
            placeholder: R.image.browserListBeerImagePlaceholder(),
            options: [
                .processor(downsamplingProcessor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.5))
            ])

        beerNameLabel.text = beerViewModel.name
    }

}
