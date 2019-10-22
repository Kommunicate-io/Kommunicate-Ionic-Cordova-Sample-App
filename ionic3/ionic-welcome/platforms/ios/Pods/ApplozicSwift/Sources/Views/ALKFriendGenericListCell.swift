//
//  ALKGenericListCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 23/04/18.
//

import UIKit

class ALKFriendGenericListCell: ALKChatBaseCell<ALKMessageViewModel> {
    open var itemTitleLabel: InsetLabel = {
        let label = InsetLabel(insets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        label.text = "title"
        // TODO: Make number of lines to 3.
        label.numberOfLines = 1
        label.font = Font.bold(size: 16.0).font()
        label.textColor = UIColor.black
        return label
    }()

    var messageView = ALKFriendMessageView()

    open var itemDescriptionLabel: VerticalAlignLabel {
        let label = VerticalAlignLabel()
        label.text = "DescriptionLabel"
        label.numberOfLines = 1
        label.font = Font.normal(size: 15.0).font()
        label.textColor = UIColor.gray
        return label
    }

    let mainBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    var itemLabelStackView: UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        return stackView
    }

    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    public enum Padding {
        enum MainStackView {
            static var bottom: CGFloat = -10.0
            static var left: CGFloat = 10
            static var right: CGFloat = -95
        }
    }

    open var actionButtons = [UIButton]()

    open var template: ALKGenericListTemplate!
    open var buttonSelected: ((_ index: Int, _ name: String) -> Void)?

    private var items = [ALKGenericListTemplate]()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func setupViews() {
        super.setupViews()
        setUpButtons()
        setUpViews()
    }

    open class func rowHeightFor(template: [ALKGenericListTemplate], viewModel: ALKMessageViewModel) -> CGFloat {
        let buttonHeight = 35
        let baseHeight: CGFloat = 20
        let padding: CGFloat = 10
        let totalButtonHeight: CGFloat = CGFloat(buttonHeight * template.count)
        return baseHeight + totalButtonHeight + padding + ALKFriendMessageView.rowHeigh(viewModel: viewModel, widthNoPadding: UIScreen.main.bounds.width - 200) + 40
    }

    @objc func buttonSelected(_ action: UIButton) {
        buttonSelected?(action.tag, action.currentTitle ?? "")
    }

    override func update(viewModel: ALKMessageViewModel) {
        messageView.update(viewModel: viewModel)
        guard let metadata = viewModel.metadata else {
            return
        }
        do {
            let cardTemplate = try TemplateDecoder.decode([ALKGenericListTemplate].self, from: metadata)
            guard let title = metadata["headerText"] as? String else {
                return
            }
            updateTitle(title)
            updateViewFor(cardTemplate)
        } catch {
            print("\(error)")
        }
    }

    private func setUpButtons() {
        actionButtons = (0 ... 7).map {
            let button = UIButton()
            button.setTitleColor(UIColor(netHex: 0x5C5AA7), for: .normal)
            button.setFont(font: UIFont.font(.bold(size: 16.0)))
            button.setTitle("Button", for: .normal)
            button.addTarget(self, action: #selector(buttonSelected(_:)), for: .touchUpInside)
            button.layer.borderWidth = 1.0
            button.tag = $0
            button.layer.borderColor = UIColor.lightGray.cgColor
            return button
        }
    }

    private func setUpViews() {
        setupConstraints()
        backgroundColor = .clear
    }

    private func setupConstraints() {
        let view = contentView

        actionButtons.forEach {
            buttonStackView.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalToConstant: 35).isActive = true
        }
        mainStackView.addArrangedSubview(itemTitleLabel)
        mainStackView.addArrangedSubview(buttonStackView)
        view.addViewsForAutolayout(views: [messageView, mainBackgroundView, mainStackView])

        messageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -95).isActive = true
        messageView.heightAnchor.constraint(lessThanOrEqualToConstant: 1000).isActive = true

        // TODO: Find alternative to layoutIfNeeded
        messageView.layoutIfNeeded()

        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Padding.MainStackView.left).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Padding.MainStackView.right).isActive = true
        mainStackView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 5).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: Padding.MainStackView.bottom).isActive = true

        itemTitleLabel.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 0).isActive = true
        itemTitleLabel.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: 0).isActive = true
        itemTitleLabel.topAnchor.constraint(equalTo: mainStackView.topAnchor, constant: 0).isActive = true
        itemTitleLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        itemTitleLabel.backgroundColor = UIColor.lightGray

        mainBackgroundView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor).isActive = true
        mainBackgroundView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor).isActive = true
        mainBackgroundView.topAnchor.constraint(equalTo: mainStackView.topAnchor).isActive = true
        mainBackgroundView.bottomAnchor.constraint(equalTo: mainStackView.bottomAnchor).isActive = true

        buttonStackView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 0).isActive = true
    }

    private func updateViewFor(_ buttons: [ALKGenericListTemplate]) {
        // Hide3 extra buttons
        actionButtons.enumerated().forEach {
            if $0 >= buttons.count { $1.isHidden = true } else { $1.isHidden = false; $1.setTitle(buttons[$0].title, for: .normal) }
        }
    }

    private func updateTitle(_ title: String?) {
        guard let text = title else {
            itemTitleLabel.isHidden = true
            return
        }
        itemTitleLabel.text = text
    }
}
