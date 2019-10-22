//
//  ReceivedMessageView.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 21/01/19.
//

import UIKit

/// Message view for receiver side.
///
/// It contains `MessageView`, time, display name and image of receiver.
/// - NOTE: Padding for message will be passed from outside. Time will be shown to the right of view.
public class ReceivedMessageView: UIView {
    // MARK: Public properties

    /// Configuration to change width height and padding of views inside ReceivedMessageView.
    public struct Config {
        public struct ProfileImage {
            public static var width: CGFloat = 37.0
            public static var height: CGFloat = 37.0
            /// Top padding of `ProfileImage` from `DisplayName`
            public static var topPadding: CGFloat = 2.0
        }

        public struct TimeLabel {
            /// Left padding of `TimeLabel` from `MessageView`
            public static var leftPadding: CGFloat = 2.0
            public static var maxWidth: CGFloat = 200.0
        }

        public struct DisplayName {
            public static var height: CGFloat = 16.0

            /// Left padding of `DisplayName` from `ProfileImage`
            public static var leftPadding: CGFloat = 10.0

            /// Right padding of `DisplayName` from `ReceivedMessageView`. Used as lessThanOrEqualTo
            public static var rightPadding: CGFloat = 20.0
        }

        public struct MessageView {
            /// Left padding of `MessageView` from `ProfileImage`
            public static var leftPadding: CGFloat = 10.0

            /// Top padding of `MessageView` from `DisplayName`
            public static var topPadding: CGFloat = 2.0

            /// Bottom padding of `MessageView` from `TimeLabel`'s bottom
            public static var bottomPadding: CGFloat = 2.0
        }
    }

    // MARK: Fileprivate properties

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.receivedMessage.bubble,
        messageStyle: MessageTheme.receivedMessage.message,
        maxWidth: maxWidth
    )

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.setStyle(MessageTheme.receivedMessage.time)
        lb.isOpaque = true
        return lb
    }()

    fileprivate var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.image = UIImage(named: "placeholder", in: Bundle.richMessageKit, compatibleWith: nil)
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        imv.layer.cornerRadius = 18.5
        imv.layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    fileprivate var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.setStyle(MessageTheme.receivedMessage.displayName)
        label.isOpaque = true
        return label
    }()

    fileprivate lazy var timeLabelWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelHeight = timeLabel.heightAnchor.constraint(equalToConstant: 0)
    fileprivate var padding: Padding
    fileprivate var maxWidth: CGFloat

    // MARK: Initializers

    /// Initializer for message view.
    ///
    /// - Parameters:
    ///   - frame: It's used to set message frame.
    ///   - padding: Padding for view.
    ///   - maxWidth: Maximum width to constrain view. USe same in rowHeight method.
    public init(frame: CGRect, padding: Padding, maxWidth: CGFloat) {
        self.padding = padding
        self.maxWidth = maxWidth
        super.init(frame: frame)
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public methods

    /// It updates the message view using `MessageModel`. Sets message text, time, name, status, image.
    ///
    /// - Parameters:
    ///   - model: Model containing information to update view.
    public func update(model: Message) {
        let message = model.text ?? "" /// Don't support nil right now
        /// Set frame
        let height = ReceivedMessageView.rowHeight(model: model, maxWidth: maxWidth, padding: padding)
        frame.size = CGSize(width: maxWidth, height: height)

        // Set message
        messageView.update(model: message)

        // Set time
        timeLabel.text = model.time
        let timeLabelSize = model.time.rectWithConstrainedWidth(
            Config.TimeLabel.maxWidth,
            font: MessageTheme.receivedMessage.time.font
        )
        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up)

        // Set name
        nameLabel.text = model.displayName

        guard let url = model.imageURL else { return }
        ImageCache.downloadImage(url: url) { [weak self] image in
            guard let image = image else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
            }
        }
    }

    /// It's used to get exact height of messageView.
    ///
    /// - NOTE: Font parameter is not used.
    /// - Parameters:
    ///   - model: Model used to update view.
    ///   - maxWidth: maxmimum allowable width for view.
    ///   - padding: padding for view. Use the same passsed while initializing.
    /// - Returns: Exact height of view.
    public static func rowHeight(model: Message, maxWidth: CGFloat, font _: UIFont = UIFont(), padding: Padding?) -> CGFloat {
        guard let padding = padding else {
            print("❌❌❌ Padding is not passed from outside. Use same passed in initialization. ❌❌❌")
            return 0
        }
        return ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model, maxWidth: maxWidth, padding: padding)
    }

    // MARK: Private methods

    private func setupConstraints() {
        addViewsForAutolayout(views: [avatarImageView, nameLabel, messageView, timeLabel])
        let nameRightPadding = max(padding.right, Config.DisplayName.rightPadding)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Config.ProfileImage.topPadding),
            avatarImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: padding.left),
            avatarImageView.widthAnchor.constraint(equalToConstant: Config.ProfileImage.width),
            avatarImageView.heightAnchor.constraint(equalToConstant: Config.ProfileImage.height),

            nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: padding.top),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Config.DisplayName.leftPadding),
            nameLabel.heightAnchor.constraint(equalToConstant: Config.DisplayName.height),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -1 * nameRightPadding),

            messageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Config.MessageView.topPadding),
            messageView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Config.MessageView.leftPadding),
            messageView.bottomAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: -1 * Config.MessageView.bottomPadding),
            messageView.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -1 * Config.TimeLabel.leftPadding),

            timeLabel.leadingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: Config.TimeLabel.leftPadding),
            timeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * padding.bottom),
            timeLabelWidth,
            timeLabelHeight,
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -1 * padding.right),
        ])
    }
}
