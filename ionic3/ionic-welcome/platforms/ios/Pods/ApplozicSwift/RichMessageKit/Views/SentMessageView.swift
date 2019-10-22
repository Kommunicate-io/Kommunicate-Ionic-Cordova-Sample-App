//
//  SentMessageView.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 21/01/19.
//

import UIKit

/// Message view for sender side.
///
/// It contains `MessageView`, time and message status(pending/sent/delivered).
/// It also contains `Config` which is used to configure views properties. It can be changed from outside.
/// - NOTE: Padding for message will be passed from outside. Time and status will be shown to the left of view with default padding.
public class SentMessageView: UIView {
    // MARK: Public properties

    /// Configuration to change width height and padding of views inside SentMessageView.
    public struct Config {
        public struct StateView {
            public static var width: CGFloat = 17.0
            public static var height: CGFloat = 9.0
        }

        public struct TimeLabel {
            /// Left padding of `TimeLabel` from `StateView`
            public static var leftPadding: CGFloat = 2.0
            public static var maxWidth: CGFloat = 200.0
        }

        public struct MessageView {
            /// Left padding of `MessageView` from `TimeLabel`
            public static var leftPadding: CGFloat = 2.0
            /// Bottom padding of `MessageView` from `TimeLabel`
            public static var bottomPadding: CGFloat = 2.0
        }
    }

    // MARK: Fileprivate Properties

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.sentMessage.bubble,
        messageStyle: MessageTheme.sentMessage.message,
        maxWidth: maxWidth
    )

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.setStyle(MessageTheme.sentMessage.time)
        lb.isOpaque = true
        return lb
    }()

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
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

    /// It updates the message view using `MessageModel`. Sets message text, time, status.
    ///
    /// - Parameters:
    ///   - model: Model containing information to update view.
    public func update(model: Message) {
        let message = model.text ?? ""
        /// Set frame
        let height = SentMessageView.rowHeight(model: model, maxWidth: maxWidth, padding: padding)
        frame.size = CGSize(width: maxWidth, height: height)

        // Set message
        messageView.update(model: message)

        // Set time and update timeLabel constraint.
        timeLabel.text = model.time
        let timeLabelSize = model.time.rectWithConstrainedWidth(Config.TimeLabel.maxWidth,
                                                                font: MessageTheme.sentMessage.time.font)
        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up) // This is amazing😱😱😱... a diff in fraction can trim.
        layoutIfNeeded()

        guard let status = model.status else { return }
        // Set status
        var statusImage = MessageTheme.sentMessage.status
        switch status {
        case .pending:
            statusImage.pending = statusImage.pending?.withRenderingMode(.alwaysTemplate)
            stateView.image = statusImage.pending
            stateView.tintColor = UIColor.red
        case .sent:
            stateView.image = statusImage.sent
        case .delivered:
            stateView.image = statusImage.delivered
        case .read:
            statusImage.read = statusImage.read?.withRenderingMode(.alwaysTemplate)
            stateView.image = statusImage.read
            stateView.tintColor = UIColor(netHex: 0x0578FF)
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
        return SentMessageViewSizeCalculator().rowHeight(messageModel: model, maxWidth: maxWidth, padding: padding)
    }

    // MARK: Private methods

    private func setupConstraints() {
        addViewsForAutolayout(views: [messageView, timeLabel, stateView])

        NSLayoutConstraint.activate([
            stateView.widthAnchor.constraint(equalToConstant: Config.StateView.width),
            stateView.heightAnchor.constraint(equalToConstant: Config.StateView.height),
            stateView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * padding.bottom),
            stateView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: padding.left),
            stateView.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -1 * Config.TimeLabel.leftPadding),

            timeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * padding.bottom),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: stateView.trailingAnchor, constant: Config.TimeLabel.leftPadding),
            timeLabelWidth,
            timeLabelHeight,
            timeLabel.trailingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -1 * Config.MessageView.leftPadding),

            messageView.topAnchor.constraint(equalTo: self.topAnchor, constant: padding.top),
            messageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * padding.right),
            messageView.leadingAnchor.constraint(greaterThanOrEqualTo: timeLabel.trailingAnchor, constant: Config.MessageView.leftPadding),
            messageView.bottomAnchor.constraint(equalTo: stateView.bottomAnchor, constant: -1 * Config.MessageView.bottomPadding),
        ])
    }
}
