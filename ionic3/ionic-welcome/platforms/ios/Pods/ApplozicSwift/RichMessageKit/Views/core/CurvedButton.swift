//
//  CurvedButton.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 18/01/19.
//

import UIKit

/// It's a curved shaped button which has methods to get the height and width for the text passed.
///
/// It also accepts optional font, color and maxWidth for rendering.
/// - NOTE: Minimum width is 45 and minimum height is 35 and cornerRadius is 15.
public class CurvedButton: UIButton {
    // MARK: Public Properties

    /// Defines the padding for text inside button.
    public static var padding: Padding = Padding(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0)

    /// Index of button. It will be used when button is tapped
    public var index: Int?

    // MARK: Internal Properties

    let title: String
    let color: UIColor
    let textFont: UIFont
    let maxWidth: CGFloat
    let delegate: Tappable?

    // MARK: Initializers

    /// Initializer for curved button.
    ///
    /// - Parameters:
    ///   - title: Text to be shown in the button.
    ///   - delegate: A delegate used to receive callbacks when button is tapped.
    ///   - font: Font for button text.
    ///   - color: Color for button text.
    ///   - maxWidth: Maximum width of button so that it can render in multiple lines of text is large.
    public init(title: String,
                delegate: Tappable,
                font: UIFont = UIFont.systemFont(ofSize: 14),
                color: UIColor = UIColor(red: 85, green: 83, blue: 183),
                maxWidth: CGFloat = UIScreen.main.bounds.width) {
        self.title = title
        self.delegate = delegate
        textFont = font
        self.color = color
        self.maxWidth = maxWidth - CurvedButton.padding.left - CurvedButton.padding.right
        super.init(frame: .zero)
        setupButton()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public methods

    /// This method calculates width of button.
    ///
    /// - Returns: Button width for the given title.
    public func buttonWidth() -> CGFloat {
        let titleWidth = title.rectWithConstrainedWidth(maxWidth, font: textFont).width.rounded(.up)
        let buttonWidth = titleWidth + CurvedButton.padding.left + CurvedButton.padding.right
        return max(buttonWidth, 45) // Minimum width is 45
    }

    /// This method calculates height of button.
    ///
    /// - Returns: Button height for the given title.
    public func buttonHeight() -> CGFloat {
        let titleHeight = title.rectWithConstrainedWidth(maxWidth, font: textFont).height.rounded(.up)
        let buttonHeight = titleHeight + CurvedButton.padding.top + CurvedButton.padding.bottom
        return max(buttonHeight, 35) // Minimum height is 35
    }

    /// This method calculates size of button.
    ///
    /// - NOTE: Pass same maxWidth and font used while creating button.
    /// - Returns: Button size for the given title.
    public class func buttonSize(text: String,
                                 maxWidth: CGFloat = UIScreen.main.bounds.width,
                                 font: UIFont = UIFont.systemFont(ofSize: 14)) -> CGSize {
        let textSize = text.rectWithConstrainedWidth(maxWidth - (padding.left + padding.right), font: font)
        var width = textSize.width.rounded(.up) + (padding.left + padding.right)
        var height = textSize.height.rounded(.up) + (padding.top + padding.bottom)
        width = max(width, 45)
        height = max(height, 35)
        return CGSize(width: width, height: height)
    }

    // MARK: Private methods

    @objc private func tapped(_: UIButton) {
        guard let delegate = delegate else { return }
        delegate.didTap(index: index, title: title)
    }

    private func setupButton() {
        /// Attributed title for button
        let attributes = [NSAttributedString.Key.font: textFont,
                          NSAttributedString.Key.foregroundColor: color]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)

        setAttributedTitle(attributedTitle, for: .normal)
        frame.size = CGSize(width: buttonWidth(), height: buttonHeight())
        widthAnchor.constraint(equalToConstant: buttonWidth()).isActive = true
        heightAnchor.constraint(equalToConstant: buttonHeight()).isActive = true
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        titleLabel?.lineBreakMode = .byWordWrapping
        backgroundColor = .clear
        layer.cornerRadius = 15
        layer.borderWidth = 2
        layer.borderColor = color.cgColor
        clipsToBounds = true

        addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
    }
}
