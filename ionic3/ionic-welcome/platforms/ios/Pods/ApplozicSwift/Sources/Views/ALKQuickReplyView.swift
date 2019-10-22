//
//  ALKQuickReplyCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 07/01/19.
//
public struct QuickReplySettings {
    public static var font = UIFont.systemFont(ofSize: 14)
    public static var color = UIColor(red: 85, green: 83, blue: 183)
}

public class ALKQuickReplyView: UIView {
    let font = QuickReplySettings.font
    let color = QuickReplySettings.color

    let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()

    public var alignLeft: Bool = true
    public var maxWidth: CGFloat = UIScreen.main.bounds.width // Need default value otherwise crash if someone don't change from outside
    public var quickReplySelected: ((_ index: Int?, _ name: String, _ dict: [String: Any]?) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(quickReplyArray: [[String: Any]]) {
        setupQuickReplyButtons(quickReplyArray)
    }

    public class func rowHeight(quickReplyArray: [[String: Any]], maxWidth: CGFloat) -> CGFloat {
        let font = QuickReplySettings.font
        var width: CGFloat = 0
        var totalHeight: CGFloat = 0
        var size = CGSize(width: 0, height: 0)
        var prevHeight: CGFloat = 0

        for dict in quickReplyArray {
            let title = dict["title"] as? String ?? ""
            size = ALKCurvedButton.buttonSize(text: title, maxWidth: maxWidth, font: font)
            let currWidth = size.width
            if currWidth > maxWidth {
                totalHeight += size.height + prevHeight + 10 // 10 padding between buttons
                width = 0
                prevHeight = 0
                continue
            }
            if width + currWidth > maxWidth {
                totalHeight += prevHeight + 10 // 10 padding between buttons
                width = currWidth + 10
                prevHeight = size.height
            } else {
                width += currWidth + 10 // 10 padding between buttons
                prevHeight = size.height
            }
        }
        totalHeight += prevHeight
        return totalHeight
    }

    private func setupConstraints() {
        addViewsForAutolayout(views: [mainStackView])
        mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func setupQuickReplyButtons(_ quickReplyArray: [[String: Any]]) {
        mainStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        var width: CGFloat = 0
        var subviews = [UIView]()
        var index: Int = 0
        for quickReply in quickReplyArray {
            guard let title = quickReply["title"] as? String else {
                continue
            }
            index += 1
            let button = curvedButton(title: title, index: index, metadata: quickReply["replyMetadata"] as? [String: Any])
            width += button.buttonWidth()

            if width >= maxWidth {
                guard !subviews.isEmpty else {
                    let stackView = horizontalStackView(subviews: [button])
                    mainStackView.addArrangedSubview(stackView)
                    width = 0
                    continue
                }
                let hiddenView = hiddenViewUsing(currWidth: width - button.buttonWidth(), maxWidth: maxWidth, subViews: subviews)
                alignLeft ? subviews.append(hiddenView) : subviews.insert(hiddenView, at: 0)
                width = button.buttonWidth() + 10
                let stackView = horizontalStackView(subviews: subviews)
                mainStackView.addArrangedSubview(stackView)
                subviews.removeAll()
                subviews.append(button)
            } else {
                width += 10
                subviews.append(button)
            }
        }
        let hiddenView = hiddenViewUsing(currWidth: width, maxWidth: maxWidth, subViews: subviews)
        alignLeft ? subviews.append(hiddenView) : subviews.insert(hiddenView, at: 0)
        let stackView = horizontalStackView(subviews: subviews)
        mainStackView.addArrangedSubview(stackView)
    }

    private func horizontalStackView(subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fill
        return stackView
    }

    private func hiddenViewUsing(currWidth: CGFloat, maxWidth: CGFloat, subViews _: [UIView]) -> UIView {
        let unusedWidth = maxWidth - currWidth - 20
        let height = (subviews[0] as? ALKCurvedButton)?.buttonHeight() ?? 0
        let size = CGSize(width: unusedWidth, height: height)

        let view = UIView()
        view.backgroundColor = .clear
        view.frame.size = size
        return view
    }

    private func curvedButton(title: String, index: Int, metadata: [String: Any]?) -> ALKCurvedButton {
        let button = ALKCurvedButton(title: title, font: font, color: color, maxWidth: maxWidth)
        button.index = index
        button.buttonSelected = { [weak self] index, title in
            self?.quickReplySelected?(index, title, metadata)
        }
        return button
    }
}
