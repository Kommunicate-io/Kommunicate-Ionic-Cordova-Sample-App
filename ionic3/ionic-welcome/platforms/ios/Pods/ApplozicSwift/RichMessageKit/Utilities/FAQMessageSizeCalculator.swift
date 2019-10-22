//
//  FAQMessageSizeCalculator.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 04/06/19.
//

import Foundation

class FAQMessageSizeCalculator {
    func rowHeight(model: FAQMessage, maxWidth: CGFloat, padding: Padding) -> CGFloat {
        var messageViewHeight: CGFloat = 0
        var faqHeight: CGFloat = 0
        if model.message.isMyMessage {
            let messageViewPadding = Padding(
                left: padding.left,
                right: padding.right,
                top: padding.top,
                bottom: SentFAQMessageCell.Config.faqTopPadding
            )
            messageViewHeight = SentMessageViewSizeCalculator().rowHeight(messageModel: model.message, maxWidth: maxWidth, padding: messageViewPadding)
            faqHeight = FAQMessageView.rowHeight(model: model, maxWidth: SentFAQMessageCell.faqWidth, style: FAQMessageTheme.sentMessage)
        } else {
            let messageViewPadding = Padding(
                left: padding.left,
                right: padding.right,
                top: padding.top,
                bottom: ReceivedFAQMessageCell.Config.faqTopPadding
            )
            messageViewHeight = ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model.message, maxWidth: maxWidth, padding: messageViewPadding)
            faqHeight = FAQMessageView.rowHeight(model: model, maxWidth: ReceivedFAQMessageCell.faqWidth, style: FAQMessageTheme.receivedMessage)
        }

        return messageViewHeight + faqHeight + padding.bottom // top will be already added in messageView
    }
}
