//
//  QuickReplyViewSizeCalculator.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 21/01/19.
//

import Foundation

class SuggestedReplyViewSizeCalculator {
    func rowHeight(model: SuggestedReplyMessage, maxWidth: CGFloat, font: UIFont) -> CGFloat {
        var width: CGFloat = 0
        var totalHeight: CGFloat = 0
        var size = CGSize(width: 0, height: 0)
        var prevHeight: CGFloat = 0

        for title in model.title {
            size = CurvedButton.buttonSize(text: title, maxWidth: maxWidth, font: font)
            let currWidth = size.width
            if currWidth > maxWidth {
                totalHeight += size.height + prevHeight + 10 // 10 padding between buttons
                width = 0
                prevHeight = 0
                continue
            }
            if width + currWidth > maxWidth {
                totalHeight += prevHeight + 10 // 10 padding between buttons
                width = currWidth + 10
                prevHeight = size.height
            } else {
                width += currWidth + 10 // 10 padding between buttons
                prevHeight = size.height
            }
        }
        totalHeight += prevHeight
        return totalHeight
    }
}
