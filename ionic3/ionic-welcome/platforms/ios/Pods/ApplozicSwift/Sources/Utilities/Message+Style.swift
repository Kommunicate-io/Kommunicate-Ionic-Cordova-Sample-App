//
//  Message+Style.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
public enum ALKMessageStyle {
    public static var displayName = Style(
        font: UIFont.font(.normal(size: 14)),
        text: .text(.gray9B)
    )

    public static var playTime = Style(
        font: UIFont.font(.normal(size: 16)),
        text: .text(.black00)
    )

    public static var time = Style(
        font: UIFont.font(.italic(size: 12)),
        text: .text(.grayCC)
    )

    // Received message text style
    public static var receivedMessage = Style(
        font: UIFont.font(.normal(size: 14)),
        text: .text(.black00)
    )

    // Sent message text style
    public static var sentMessage = Style(
        font: UIFont.font(.normal(size: 14)),
        text: .text(.black00)
    )

    @available(*, deprecated, message: "Use `receivedMessage` and `sentMessage`")
    public static var message = Style(
        font: UIFont.font(.normal(size: 14)),
        text: .text(.black00)
    ) {
        didSet {
            receivedMessage = message
            sentMessage = message
        }
    }

    public enum BubbleStyle {
        case edge
        case round
    }

    public struct Bubble {
        /// Message bubble's background color.
        public var color: UIColor

        /// Message bubble corner Radius
        public var cornerRadius: CGFloat

        /// BubbleStyle of the message bubble.
        public var style: BubbleStyle

        /// Width padding which will be used for message view's
        /// right and left padding.
        public let widthPadding: CGFloat

        public init(color: UIColor, style: BubbleStyle) {
            self.color = color
            self.style = style
            widthPadding = 10.0
            cornerRadius = 12
        }
    }

    public static var sentBubble = Bubble(color: UIColor(netHex: 0xF1F0F0), style: .edge)
    public static var receivedBubble = Bubble(color: UIColor(netHex: 0xF1F0F0), style: .edge)
}
