//
//  SentMessageViewSizeCalculator.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 26/01/19.
//

import Foundation

class SentMessageViewSizeCalculator {
    func rowHeight(messageModel: Message, maxWidth: CGFloat, padding: Padding) -> CGFloat {
        let message = messageModel.text ?? ""
        let config = SentMessageView.Config.self
        let totalWidthPadding = padding.left + padding.right + config.MessageView.leftPadding + config.TimeLabel.leftPadding

        let timeLabelWidth = messageModel.time.rectWithConstrainedWidth(config.TimeLabel.maxWidth, font: MessageTheme.sentMessage.time.font).width.rounded(.up)

        let messageWidth = maxWidth - (totalWidthPadding + config.StateView.width + timeLabelWidth)

        let messageHeight = MessageViewSizeCalculator().rowHeight(
            text: message,
            font: MessageTheme.sentMessage.message.font,
            maxWidth: messageWidth,
            padding: MessageTheme.sentMessage.bubble.padding
        )

        return messageHeight + padding.top + padding.bottom + config.MessageView.bottomPadding
    }
}
