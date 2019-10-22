//
//  ALKMessageCell.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Applozic
import Foundation
import Kingfisher
import UIKit

// MARK: - ALKMyMessageCell

open class ALKMyMessageCell: ALKMessageCell {
    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    static var bubbleViewRightPadding: CGFloat = {
        /// For edge add extra 5
        guard ALKMessageStyle.sentBubble.style == .edge else {
            return ALKMessageStyle.sentBubble.widthPadding
        }
        return ALKMessageStyle.sentBubble.widthPadding + 5
    }()

    struct Padding {
        struct ReplyView {
            static let height: CGFloat = 80.0
            static let left: CGFloat = 5.0
            static let right: CGFloat = 5.0
            static let top: CGFloat = 5.0
        }

        struct ReplyNameLabel {
            static let right: CGFloat = 10.0
            static let height: CGFloat = 30.0
        }

        struct ReplyMessageLabel {
            static let right: CGFloat = 10.0
            static let top: CGFloat = 5.0
            static let height: CGFloat = 30.0
        }

        struct PreviewImageView {
            static let height: CGFloat = 50.0
            static let width: CGFloat = 70.0
            static let right: CGFloat = 10.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5.0
        }

        struct MessageView {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 10.0
        }

        struct BubbleView {
            static let left: CGFloat = 95.0
            static let bottom: CGFloat = 8.0
            static let right: CGFloat = 10.0
        }

        struct StateView {
            static let height: CGFloat = 9.0
            static let width: CGFloat = 17.0
            static let right: CGFloat = 2.0
        }
    }

    struct ConstraintIdentifier {
        struct ReplyNameLabel {
            static let height = "ReplyNameHeight"
        }

        struct ReplyMessageLabel {
            static let height = "ReplyMessageHeight"
        }

        struct PreviewImage {
            static let height = "ReplyPreviewImageHeight"
            static let width = "ReplyPreviewImageWidth"
        }

        static let replyViewHeightIdentifier = "ReplyViewHeight"
    }

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [stateView])

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Padding.BubbleView.bottom
            ),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: Padding.BubbleView.left
            ),
            bubbleView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Padding.BubbleView.right
            ),

            replyView.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: Padding.ReplyView.top
            ),
            replyView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyViewHeightIdentifier
            ),
            replyView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.ReplyView.left
            ),
            replyView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -Padding.ReplyView.right
            ),

            previewImageView.topAnchor.constraint(
                equalTo: replyNameLabel.topAnchor,
                constant: Padding.PreviewImageView.top
            ),
            previewImageView.trailingAnchor.constraint(
                equalTo: replyView.trailingAnchor,
                constant: -Padding.PreviewImageView.right
            ),
            previewImageView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.PreviewImage.height
            ),
            previewImageView.widthAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.PreviewImage.width
            ),

            replyNameLabel.leadingAnchor.constraint(equalTo: replyView.leadingAnchor),
            replyNameLabel.topAnchor.constraint(equalTo: replyView.topAnchor),
            replyNameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: previewImageView.leadingAnchor,
                constant: -Padding.ReplyNameLabel.right
            ),
            replyNameLabel.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.ReplyNameLabel.height
            ),

            replyMessageLabel.leadingAnchor.constraint(equalTo: replyView.leadingAnchor),
            replyMessageLabel.topAnchor.constraint(
                equalTo: replyNameLabel.bottomAnchor,
                constant: Padding.ReplyMessageLabel.top
            ),
            replyMessageLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: previewImageView.leadingAnchor,
                constant: -Padding.ReplyMessageLabel.right
            ),
            replyMessageLabel.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.ReplyMessageLabel.height
            ),

            emailTopView.topAnchor.constraint(
                equalTo: replyView.bottomAnchor,
                constant: Padding.MessageView.top
            ),
            emailTopView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKMessageStyle.sentBubble.widthPadding
            ),
            emailTopView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMyMessageCell.bubbleViewRightPadding
            ),
            emailTopHeight,

            messageView.topAnchor.constraint(
                equalTo: emailTopView.bottomAnchor
            ),
            messageView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKMessageStyle.sentBubble.widthPadding
            ),
            messageView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMyMessageCell.bubbleViewRightPadding
            ),
            messageView.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -Padding.MessageView.bottom
            ),

            stateView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            stateView.trailingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: -Padding.StateView.right
            ),
            stateView.widthAnchor.constraint(equalToConstant: Padding.StateView.width),
            stateView.heightAnchor.constraint(equalToConstant: Padding.StateView.height),

            timeLabel.trailingAnchor.constraint(
                equalTo: stateView.leadingAnchor,
                constant: -2.0
            ),
            timeLabel.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: 2
            ),
        ])
    }

    open override func setupStyle() {
        super.setupStyle()
        messageView.setStyle(ALKMessageStyle.sentMessage)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.tintColor = ALKMessageStyle.sentBubble.color
            bubbleView.image = bubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false, showHangOverImage: false)
        } else {
            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
            bubbleView.tintColor = ALKMessageStyle.sentBubble.color
            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
        }
    }

    open override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel, style: ALKMessageStyle.sentMessage)

        if viewModel.isReplyMessage {
            guard
                let metadata = viewModel.metadata,
                let replyId = metadata[AL_MESSAGE_REPLY_KEY] as? String,
                let actualMessage = getMessageFor(key: replyId)
            else { return }
            showReplyView(true)
            if actualMessage.messageType == .text || actualMessage.messageType == .html {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = 0
            } else {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = Padding.PreviewImageView.width
            }
        } else {
            showReplyView(false)
        }

        if viewModel.isAllRead {
            stateView.image = UIImage(named: "read_state_3", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor(netHex: 0x0578FF)
        } else if viewModel.isAllReceived {
            stateView.image = UIImage(named: "read_state_2", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = nil
        } else if viewModel.isSent {
            stateView.image = UIImage(named: "read_state_1", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = nil
        } else {
            stateView.image = UIImage(named: "seen_state_0", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.red
        }
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,
                                 width: CGFloat) -> CGFloat {
        /// Calculating messageHeight
        let leftSpacing = Padding.BubbleView.left + ALKMessageStyle.sentBubble.widthPadding
        let rightSpacing = Padding.BubbleView.right + bubbleViewRightPadding
        let messageWidth = width - (leftSpacing + rightSpacing)
        let messageHeight = super.messageHeight(viewModel: viewModel, width: messageWidth, font: ALKMessageStyle.sentMessage.font)
        let heightPadding = Padding.MessageView.top + Padding.MessageView.bottom + Padding.BubbleView.bottom + Padding.ReplyView.top

        let totalHeight = messageHeight + heightPadding
        guard let metadata = viewModel.metadata,
            metadata[AL_MESSAGE_REPLY_KEY] as? String != nil else {
            return totalHeight
        }
        return totalHeight + Padding.ReplyView.height
    }

    fileprivate func showReplyView(_ show: Bool) {
        replyView
            .constraint(withIdentifier: ConstraintIdentifier.replyViewHeightIdentifier)?
            .constant = show ? Padding.ReplyView.height : 0
        replyNameLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyNameLabel.height)?
            .constant = show ? Padding.ReplyNameLabel.height : 0
        replyMessageLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyMessageLabel.height)?
            .constant = show ? Padding.ReplyMessageLabel.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.height)?
            .constant = show ? Padding.PreviewImageView.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?
            .constant = show ? Padding.PreviewImageView.width : 0

        replyView.isHidden = !show
        replyNameLabel.isHidden = !show
        replyMessageLabel.isHidden = !show
        previewImageView.isHidden = !show
    }

    // MARK: - ChatMenuCell

    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.image = bubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false, showHangOverImage: true)
        }
    }

    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.image = bubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false, showHangOverImage: false)
        }
    }
}
