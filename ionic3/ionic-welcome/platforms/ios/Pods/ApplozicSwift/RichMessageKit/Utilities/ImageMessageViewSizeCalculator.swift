//
//  SentImageMessageViewSizeCalculator.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 11/02/19.
//

import Foundation

class ImageMessageViewSizeCalculator {
    func rowHeight(model: ImageMessage, maxWidth: CGFloat, padding: Padding) -> CGFloat {
        var messageViewPadding: Padding!
        var messageViewHeight: CGFloat = 0
        if model.message.isMyMessage {
            messageViewPadding = Padding(
                left: padding.left,
                right: padding.right,
                top: padding.top,
                bottom: SentImageMessageCell.Config.imageBubbleTopPadding
            )
            messageViewHeight = SentMessageViewSizeCalculator().rowHeight(messageModel: model.message, maxWidth: maxWidth, padding: messageViewPadding)
        } else {
            messageViewPadding = Padding(
                left: padding.left,
                right: padding.right,
                top: padding.top,
                bottom: ReceivedImageMessageCell.Config.imageBubbleTopPadding
            )
            messageViewHeight = ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model.message, maxWidth: maxWidth, padding: messageViewPadding)
        }

        let imageBubbleHeight = ImageBubbleSizeCalculator().rowHeight(model: model, maxWidth: maxWidth)
        return messageViewHeight + imageBubbleHeight + padding.bottom // top will be already added in messageView
    }
}
