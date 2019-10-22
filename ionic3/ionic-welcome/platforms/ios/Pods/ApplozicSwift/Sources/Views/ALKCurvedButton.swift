//
//  ALKQuickReplyButton.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 07/01/19.
//

import UIKit

/// It's a curved shaped button which has methods to get the height and, width for the text passed.
///
/// It also accepts optional font, color and maxWidth for rendering.
/// - NOTE: Minimum width is 45 and minimum height is 35
public class ALKCurvedButton: UIButton {
    var title: String
    var color: UIColor
    var textFont: UIFont
    var maxWidth: CGFloat

    public struct Padding {
        public static var left: CGFloat = 16.0
        public static var right: CGFloat = 16.0
        public static var top: CGFloat = 8.0
        public static var bottom: CGFloat = 8.0
    }

    public var index: Int?
    public var buttonSelected: ((_ index: Int?, _ name: String) -> Void)?

    // MARK: - Initializers

    /// Initializer for curved button.
    ///
    /// - Parameters:
    ///   - title: Text to be shown in the button
    ///   - font: Font for button text
    ///   - color: Color for button text
    ///   - maxWidth: Maximum width of button so that it can render in multiple lines of text is large.
    public init(title: String,
                font: UIFont = UIFont.systemFont(ofSize: 14),
                color: UIColor = UIColor(red: 85, green: 83, blue: 183),
                maxWidth: CGFloat = UIScreen.main.bounds.width) {
        self.title = title
        textFont = font
        self.color = color
        self.maxWidth = maxWidth - Padding.left - Padding.right
        super.init(frame: .zero)
        setupButton()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    /// This method calculates width of button.
    ///
    /// - Returns: Button width for the given title
    public func buttonWidth() -> CGFloat {
        let titleWidth = title.rectWithConstrainedWidth(maxWidth, font: textFont).width
        var buttonWidth = titleWidth + Padding.left + Padding.right
        return max(buttonWidth, 45) // Minimum width is 45
    }

    /// This method calculates height of button.
    ///
    /// - Returns: Button height for the given title
    public func buttonHeight() -> CGFloat {
        let titleHeight = title.rectWithConstrainedWidth(maxWidth, font: textFont).height
        let buttonHeight = titleHeight + Padding.top + Padding.bottom
        return max(buttonHeight, 35) // Minimum height is 35
    }

    /// This method calculates size of button.
    ///
    /// - Returns: Button size for the given title
    public class func buttonSize(text: String, maxWidth: CGFloat, font: UIFont) -> CGSize {
        let textSize = text.rectWithConstrainedWidth(maxWidth - (Padding.left + Padding.right), font: font)
        var width = textSize.width + (Padding.left + Padding.right)
        var height = textSize.height + (Padding.top + Padding.bottom)
        width = max(width, 45)
        height = max(height, 35)
        return CGSize(width: width, height: height)
    }

    // MARK: - Private methods.

    @objc private func tapped(_: UIButton) {
        guard let buttonSelected = buttonSelected else {
            return
        }
        buttonSelected(index, title)
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
