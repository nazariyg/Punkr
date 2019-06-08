// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import UIKit
import Cornerstones

public class UIStyledTableView: UITableView {

    // MARK: - Lifecycle

    public override init(frame: CGRect, style: Style) {
        super.init(frame: frame, style: style)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = Config.shared.appearance.defaultBackgroundColor
        contentInsetAdjustmentBehavior = .never
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if let contentTone = baseViewController?.contentTone {
            switch contentTone {
            case .light: indicatorStyle = .black
            case .dark: indicatorStyle = .white
            }
        }
    }

    // MARK: - Cells

    public func registerCell<Cell: UITableViewCell>(_ cellType: Cell.Type) {
        register(cellType, forCellReuseIdentifier: fullStringType(cellType))
    }

    public func dequeueCell<Cell: UITableViewCell>(_ cellType: Cell.Type, forIndexPath indexPath: IndexPath) -> Cell {
        return dequeueReusableCell(withIdentifier: fullStringType(cellType), for: indexPath) as! Cell
    }

}
