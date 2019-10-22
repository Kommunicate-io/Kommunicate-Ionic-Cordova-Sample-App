//
//  GenericCardsMessageView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 03/12/18.
//

import Foundation
import Kingfisher

class ALKFriendMessageView: UIView {
    private var widthPadding: CGFloat = CGFloat(ALKMessageStyle.receivedBubble.widthPadding)

    fileprivate lazy var messageView: ALKHyperLabel = {
        let label = ALKHyperLabel(frame: .zero)
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        return label
    }()

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.isOpaque = true
        return lb
    }()

    public var bubbleView: UIImageView = {
        let bv = UIImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = false
        bv.isOpaque = true
        return bv
    }()

    public var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    fileprivate var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()

    enum Padding {
        enum MessageView {
            static let top: CGFloat = 4
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        setupViews()
        setupStyle()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupStyle() {
        if ALKMessageStyle.receivedBubble.style == .edge {
            let image = UIImage(named: "chat_bubble_rounded", in: Bundle.applozic, compatibleWith: nil)
            bubbleView.tintColor = ALKMessageStyle.receivedBubble.color
            bubbleView.image = image?.imageFlippedForRightToLeftLayoutDirection()
        } else {
            bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            bubbleView.tintColor = ALKMessageStyle.receivedBubble.color
            bubbleView.backgroundColor = ALKMessageStyle.receivedBubble.color
        }
    }

    func setupViews() {
        addViewsForAutolayout(views: [avatarImageView, nameLabel, bubbleView, messageView, timeLabel])
        bringSubviewToFront(messageView)

        nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 57).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -57).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true

        avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
        avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 0).isActive = true

        avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9).isActive = true

        avatarImageView.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -18).isActive = true

        avatarImageView.heightAnchor.constraint(equalToConstant: 37).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true

        messageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.MessageView.top).isActive = true
        messageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor).isActive = true

        messageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -2).isActive = true
        messageView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 18).isActive = true

        bubbleView.topAnchor.constraint(equalTo: messageView.topAnchor, constant: -2).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 2).isActive = true

        bubbleView.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -widthPadding).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: widthPadding).isActive = true

        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 10).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
    }

    func update(viewModel: ALKMessageViewModel) {
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }

        nameLabel.text = viewModel.displayName
        nameLabel.setStyle(ALKMessageStyle.displayName)
        messageView.text = viewModel.message ?? ""
        messageView.setStyle(ALKMessageStyle.receivedMessage)
        timeLabel.text = viewModel.time
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    class func rowHeight(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        let minimumHeight: CGFloat = 60 // 55 is avatar image... + padding
        guard let message = viewModel.message else {
            return minimumHeight
        }
        let font = ALKMessageStyle.receivedMessage.font
        let messageWidth = width - 64 // left padding 9 + 18 + 37
        var messageHeight = message.heightWithConstrainedWidth(messageWidth, font: font)
        messageHeight += 30 // 6 + 16 + 4 + 2 + 2
        return max(messageHeight, minimumHeight)
    }

    class func rowHeigh(viewModel: ALKMessageViewModel, widthNoPadding: CGFloat) -> CGFloat {
        var messageHeigh: CGFloat = 0

        if let message = viewModel.message {
            let maxSize = CGSize(width: widthNoPadding, height: CGFloat.greatestFiniteMagnitude)

            let font = ALKMessageStyle.receivedMessage.font
            let color = ALKMessageStyle.receivedMessage.text

            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byWordWrapping
            style.headIndent = 0
            style.tailIndent = 0
            style.firstLineHeadIndent = 0
            style.minimumLineHeight = 17
            style.maximumLineHeight = 17

            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: color,
            ]

            var size = CGSize()
            if viewModel.messageType == .html {
                guard let htmlText = message.data.attributedString else { return 30 }
                let mutableText = NSMutableAttributedString(attributedString: htmlText)
                let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.paragraphStyle: style]
                mutableText.addAttributes(attributes, range: NSRange(location: 0, length: mutableText.length))
                size = mutableText.boundingRect(with: maxSize, options: [NSStringDrawingOptions.usesFontLeading, NSStringDrawingOptions.usesLineFragmentOrigin], context: nil).size
            } else {
                let attrbString = NSAttributedString(string: message, attributes: attributes)
                let framesetter = CTFramesetterCreateWithAttributedString(attrbString)
                size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: 0), nil, maxSize, nil)
            }
            messageHeigh = ceil(size.height) + 10
            return messageHeigh
        }
        return messageHeigh + 50
    }
}
