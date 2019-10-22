//
//  ImageMessageViewSizeCalculator.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 06/02/19.
//

import Foundation

class ImageBubbleSizeCalculator {
    func rowHeight(model: ImageMessage, maxWidth: CGFloat) -> CGFloat {
        let messageStyle = model.message.isMyMessage ? ImageBubbleTheme.sentMessage : ImageBubbleTheme.receivedMessage

        let padding = messageStyle.bubble.padding
        let font = messageStyle.captionStyle.font

        let imageHeight = maxWidth * messageStyle.heightRatio

        var totalPadding = padding.top + padding.bottom
        /// Calculate caption height
        let width = maxWidth * messageStyle.widthRatio
        let captionWidth = width - (padding.left + padding.right)
        guard let caption = model.caption else {
            return totalPadding + imageHeight
        }
        let captionHeight = caption.rectWithConstrainedWidth(captionWidth, font: font).height.rounded(.up)
        totalPadding += ImageContainer.captionTopPadding
        return imageHeight + captionHeight + totalPadding
    }
}
