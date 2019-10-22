//
//  Style.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 18/01/19.
//

import Foundation

/// It is used to set set style for a view.
public struct Style {
    public let font: UIFont
    public let text: UIColor
    public let background: UIColor

    public init(font: UIFont, text: UIColor, background: UIColor) {
        self.font = font
        self.text = text
        self.background = background
    }

    public init(font: UIFont, text: UIColor) {
        self.font = font
        self.text = text
        background = .clear
    }
}
