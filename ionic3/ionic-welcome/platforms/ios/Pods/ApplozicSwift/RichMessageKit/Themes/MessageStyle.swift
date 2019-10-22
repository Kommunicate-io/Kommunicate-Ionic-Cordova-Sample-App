//
//  MessageStyle.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 18/01/19.
//

import Foundation

/// Image for all cases of `MessageStatus`
public struct StatusImage {
    public var pending = UIImage(named: "pending", in: Bundle.richMessageKit, compatibleWith: nil)

    public var sent = UIImage(named: "sent", in: Bundle.richMessageKit, compatibleWith: nil)

    public var delivered = UIImage(named: "delivered", in: Bundle.richMessageKit, compatibleWith: nil)

    public var read = UIImage(named: "read", in: Bundle.richMessageKit, compatibleWith: nil)

    public init() {}
}

public struct MessageStyle {
    /// Style for display name
    public var displayName = Style(
        font: UIFont.systemFont(ofSize: 14),
        text: UIColor.darkText
    )

    /// Style for message text.
    public var message = Style(
        font: UIFont.systemFont(ofSize: 14),
        text: UIColor.black
    )

    /// Style for time.
    public var time = Style(
        font: UIFont.systemFont(ofSize: 12),
        text: UIColor.darkText
    )

    /// Style for message bubble
    public var bubble = MessageBubbleStyle(color: UIColor.lightGray, cornerRadius: 5, padding: Padding(left: 10, right: 10, top: 5, bottom: 5))

    /// Image for all cases of `MessageStatus`
    public var status = StatusImage()

    public init() {}
}

/// Message view theme.
public struct MessageTheme {
    /// Message style for sent message
    public static var sentMessage: MessageStyle = MessageStyle()

    /// Message style for received message
    public static var receivedMessage: MessageStyle = MessageStyle()
}
