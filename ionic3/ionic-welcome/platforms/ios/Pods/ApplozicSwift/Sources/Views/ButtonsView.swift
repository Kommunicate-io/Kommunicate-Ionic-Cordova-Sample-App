//
//  ButtonsView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 17/01/19.
//

import Foundation

public struct MessageButtonConfig {
    public static var font = UIFont(name: "HelveticaNeue", size: 14) ?? UIFont.systemFont(ofSize: 14)

    public struct SubmitButton {
        public static var textColor = UIColor(red: 85, green: 83, blue: 183)
    }

    public struct LinkButton {
        public static var textColor = UIColor(red: 85, green: 83, blue: 183)
    }
}

public class ButtonsView: UIView {
    let font = MessageButtonConfig.font

    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 2
        stackView.alignment = stackViewAlignment
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()

    public var maxWidth: CGFloat!
    public var stackViewAlignment: UIStackView.Alignment = .leading {
        didSet {
            mainStackView.alignment = stackViewAlignment
        }
    }

    public var buttonSelected: ((_ index: Int, _ name: String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(payload: [[String: Any]]) {
        mainStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        for index in 0 ..< payload.count {
            let dict = payload[index]
            guard let type = dict["type"] as? String, type == "link" else {
                // Submit button
                let name = dict["name"] as? String ?? ""
                let button = submitButton(title: name, index: index)
                mainStackView.addArrangedSubview(button)
                continue
            }
            // Link Button
            let name = dict["name"] as? String ?? ""
            let button = linkButton(title: name, index: index)
            mainStackView.addArrangedSubview(button)
        }
    }

    public class func rowHeight(payload: [[String: Any]], maxWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 0
        for dict in payload {
            let title = dict["name"] as? String ?? ""
            let currHeight = ALKCurvedButton.buttonSize(text: title, maxWidth: maxWidth, font: MessageButtonConfig.font).height
            height += currHeight + 2 // StackView spacing
        }
        return height
    }

    private func setupConstraints() {
        addViewsForAutolayout(views: [mainStackView])
        mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func submitButton(title: String, index: Int) -> ALKCurvedButton {
        let color = MessageButtonConfig.SubmitButton.textColor
        let button = ALKCurvedButton(title: title, font: font, color: color, maxWidth: maxWidth)
        button.index = index
        button.buttonSelected = { [weak self] tag, title in
            self?.buttonSelected?(tag!, title)
        }
        return button
    }

    private func linkButton(title: String, index: Int) -> ALKCurvedButton {
        let color = MessageButtonConfig.LinkButton.textColor
        let button = ALKCurvedButton(title: title, font: font, color: color, maxWidth: maxWidth)
        button.index = index
        button.layer.borderWidth = 0

        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font,
                                                         NSAttributedString.Key.foregroundColor: color,
                                                         NSAttributedString.Key.underlineStyle: 1]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.buttonSelected = { [weak self] tag, title in
            self?.buttonSelected?(tag!, title)
        }
        return button
    }
}
