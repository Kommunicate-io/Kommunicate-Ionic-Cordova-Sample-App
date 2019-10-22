//
//  MessageView.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 18/01/19.
//

import UIKit

/// Its a view that displays text on top of a bubble.
public class MessageView: UIView {
    // MARK: Internal Properties

    let maxWidth: CGFloat

    let messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    let bubbleView: UIView = {
        let view = UIView()
        return view
    }()

    let bubbleStyle: MessageBubbleStyle
    var padding: Padding
    var messageStyle: Style

    // MARK: Initializers

    /// Initializer for `MessageView`
    ///
    /// - Parameters:
    ///   - bubbleStyle: Configuration for message bubble like color and corner radius.
    ///   - messageStyle: Configuration for message text.
    ///   - maxWidth: Maximum width to constrain current view.
    public init(bubbleStyle: MessageBubbleStyle,
                messageStyle: Style,
                maxWidth: CGFloat) {
        self.bubbleStyle = bubbleStyle
        padding = bubbleStyle.padding
        self.messageStyle = messageStyle
        self.maxWidth = maxWidth
        super.init(frame: .zero)
        setupBubbleView()
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public methods

    /// It sets message in `MessageView`
    ///
    /// - Parameter text: Text to be displayed in the view.
    public func update(model: String) {
        /// Set frame size.
        let height = MessageView.rowHeight(model: model, maxWidth: maxWidth, font: messageStyle.font, padding: bubbleStyle.padding)
        frame.size = CGSize(width: maxWidth, height: height)

        messageLabel.text = model
        messageLabel.setStyle(messageStyle)
        layoutIfNeeded()
    }

    /// It calculates height for `MessageView` based on the text passed and maximum width allowed for the view.
    ///
    /// - Parameters:
    ///   - text: Text set in messageView.
    ///   - maxWidth: Maximum allowable width for the view.
    ///   - font: message text font. Use same as passed while initialization in `messageStyle`.
    ///   - padding: message bubble padding. Use the same passed while initialization in `bubbleStyle`.
    /// - Returns: Height for `MessageView` based on passed parameters
    public static func rowHeight(model: String,
                                 maxWidth: CGFloat,
                                 font: UIFont,
                                 padding: Padding?) -> CGFloat {
        guard let padding = padding else {
            print("❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌")
            print("😱😱😱😱😱😱😱😱 Padding is not passed from outside.")
            print("Use the padding of bubbleStyle that is passed while initialization")
            print("❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌")
            return 0
        }
        return MessageViewSizeCalculator().rowHeight(text: model,
                                                     font: font,
                                                     maxWidth: maxWidth,
                                                     padding: padding)
    }

    // MARK: Private methods

    private func setupBubbleView() {
        bubbleView.backgroundColor = bubbleStyle.color
        bubbleView.layer.cornerRadius = bubbleStyle.cornerRadius
        bubbleView.clipsToBounds = true
    }

    private func setupConstraints() {
        addViewsForAutolayout(views: [messageLabel, bubbleView])
        bringSubviewToFront(messageLabel)

        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bubbleView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bubbleView.topAnchor.constraint(equalTo: self.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            messageLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: padding.top),
            messageLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * padding.bottom),
            messageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: padding.left),
            messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * padding.right),
        ])
    }
}
