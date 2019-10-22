//
//  UITableView+Extension.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func scrollToBottomWithScroll() {
        scrollToBottom(animated: true)
    }

    func scrollToBottomSection1(animated: Bool = true) {
        let indexPath = IndexPath(row: 0, section: 1)
        scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    func scrollToBottom(animated: Bool = true) {
        if numberOfSections > 0 {
            let sction = numberOfSections - 1
            let rows = numberOfRows(inSection: sction)

            if rows > 0 {
                let indexPath = IndexPath(row: rows - 1, section: sction)
                scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }

    var bottomOffset: CGPoint {
        return CGPoint(x: 0, y: contentSize.height - bounds.size.height + contentInset.bottom)
    }

    var isAtBottom: Bool {
        return bottomOffset.y - contentOffset.y <= 90
    }

    var isAtBottom1: Bool {
        return bottomOffset.y - contentOffset.y <= 1
    }

    func scrollToBottomByOfset(animated: Bool = true) {
        if bottomOffset.y > 0 {
            setContentOffset(bottomOffset, animated: animated)
        }
    }

    func isCellVisible(section: Int, row: Int) -> Bool {
        guard let indexes = self.indexPathsForVisibleRows else { return false }
        return indexes.contains { $0.section == section && $0.row == row }
    }
}
