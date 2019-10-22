//
//  MessageBubbleStyle.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 18/01/19.
//

import Foundation

public struct MessageBubbleStyle {
    public var color: UIColor
    public var cornerRadius: CGFloat
    public var padding: Padding

    /// Initializer for message bubble style
    ///
    /// - Parameters:
    ///   - color: bubble's background color.
    ///   - cornerRadius: bubble's corner radius.
    ///   - padding: bubble's padding.
    public init(color: UIColor, cornerRadius: CGFloat, padding: Padding) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
}
