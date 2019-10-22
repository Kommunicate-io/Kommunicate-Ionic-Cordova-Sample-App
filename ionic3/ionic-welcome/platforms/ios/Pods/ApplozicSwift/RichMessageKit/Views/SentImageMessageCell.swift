//
//  SentImageMessageView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 20/05/19.
//

import UIKit

public class SentImageMessageCell: UITableViewCell {
    // MARK: - Public properties

    /// It is used to inform the delegate that the image is tapped. URL of tapped image is sent.
    public var delegate: Tappable?

    public struct Config {
        public static var imageBubbleTopPadding: CGFloat = 4
        public static var padding = Padding(left: 60, right: 10, top: 10, bottom: 10)
        public static var maxWidth = UIScreen.main.bounds.width
    }

    // MARK: - Fileprivate properties

    fileprivate lazy var messageView = SentMessageView(
        frame: .zero,
        padding: messageViewPadding,
        maxWidth: Config.maxWidth
    )
    fileprivate var messageViewPadding: Padding
    fileprivate var imageBubble: ImageContainer
    fileprivate var imageBubbleWidth: CGFloat
    fileprivate lazy var messageViewHeight = messageView.heightAnchor.constraint(equalToConstant: 0)
    fileprivate var imageUrl: String?

    // MARK: - Initializer

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        messageViewPadding = Padding(left: Config.padding.left,
                                     right: Config.padding.right,
                                     top: Config.padding.top,
                                     bottom: Config.imageBubbleTopPadding)
        imageBubble = ImageContainer(frame: .zero, maxWidth: Config.maxWidth, isMyMessage: true)
        imageBubbleWidth = Config.maxWidth * ImageBubbleTheme.sentMessage.widthRatio
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        setupGesture()
        backgroundColor = .clear
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates the `ImageMessageView`.
    ///
    /// - Parameter model: object that conforms to `ImageMessage`
    public func update(model: ImageMessage) {
        guard model.message.isMyMessage else {
            print("😱😱😱Inconsistent information passed to the view.😱😱😱")
            print("For SentMessage value of isMyMessage should be true")
            return
        }
        messageView.update(model: model.message)
        messageViewHeight.constant = SentMessageView.rowHeight(
            model: model.message,
            maxWidth: Config.maxWidth,
            padding: messageViewPadding
        )

        /// Set frame
        let height = SentImageMessageCell.rowHeight(model: model)
        frame.size = CGSize(width: Config.maxWidth, height: height)

        imageUrl = model.url
        imageBubble.update(model: model)
    }

    /// It is used to get exact height of `ImageMessageView` using messageModel, width and padding
    ///
    /// - NOTE: Font is not used. Change `ImageBubbleStyle.captionStyle.font`
    /// - Parameters:
    ///   - model: object that conforms to `ImageMessage`
    /// - Returns: exact height of the view.
    public static func rowHeight(model: ImageMessage) -> CGFloat {
        return ImageMessageViewSizeCalculator().rowHeight(model: model, maxWidth: Config.maxWidth, padding: Config.padding)
    }

    private func setupConstraints() {
        addViewsForAutolayout(views: [messageView, imageBubble])

        NSLayoutConstraint.activate([
            messageView.topAnchor.constraint(equalTo: self.topAnchor),
            messageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            messageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            messageViewHeight,

            imageBubble.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 0),
            imageBubble.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * Config.padding.right),
            imageBubble.widthAnchor.constraint(equalToConstant: imageBubbleWidth),
            imageBubble.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * Config.padding.bottom),
        ])
    }

    @objc private func imageTapped() {
        guard let delegate = delegate else {
            print("❌❌❌ Delegate is not set. To handle image click please set delegate.❌❌❌")
            return
        }
        guard let imageUrl = imageUrl else {
            print("😱😱😱 ImageUrl is found nil. 😱😱😱")
            return
        }
        delegate.didTap(index: 0, title: imageUrl)
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGesture.numberOfTapsRequired = 1
        imageBubble.addGestureRecognizer(tapGesture)
    }
}
