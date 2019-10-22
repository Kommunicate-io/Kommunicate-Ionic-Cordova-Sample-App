//
//  MessageViewSizeCalculator.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 21/01/19.
//

import Foundation

class MessageViewSizeCalculator {
    func rowHeight(text: String, font: UIFont, maxWidth: CGFloat, padding: Padding) -> CGFloat {
        let messageWidth = maxWidth - (padding.left + padding.right)
        let size = text.rectWithConstrainedWidth(messageWidth, font: font)
        return size.height.rounded(.up) + padding.top + padding.bottom
    }
}
