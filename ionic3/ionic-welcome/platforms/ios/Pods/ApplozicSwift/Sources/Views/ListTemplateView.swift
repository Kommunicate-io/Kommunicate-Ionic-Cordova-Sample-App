//
//  ListTemplateView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 18/02/19.
//

import Kingfisher
import UIKit

class ListTemplateElementView: UIView {
    static let font = UIFont(name: "Helvetica", size: 14) ?? UIFont.systemFont(ofSize: 14)

    let thumbnail: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    let title: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.autoresizingMask = .flexibleLeftMargin
        label.font = ListTemplateElementView.font
        label.textColor = UIColor(red: 86, green: 84, blue: 84)
        return label
    }()

    let subtitle: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.autoresizingMask = .flexibleLeftMargin
        label.font = ListTemplateElementView.font
        label.textColor = UIColor(red: 121, green: 116, blue: 116)
        return label
    }()

    var item: ListTemplate.Element?
    var selected: ((_ text: String?, _ action: ListTemplate.Action) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupAction()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: ListTemplate.Element) {
        self.item = item
        title.text = item.title
        subtitle.text = item.description
        guard let urlString = item.imgSrc, let url = URL(string: urlString) else {
            thumbnail.isHidden = true
            layoutIfNeeded()
            return
        }
        thumbnail.isHidden = false
        thumbnail.kf.setImage(with: url)
        layoutIfNeeded()
    }

    static func height() -> CGFloat {
        let title: String = "Dummy text"
        let maxWidth: CGFloat = UIScreen.main.bounds.width
        let size = CGSize(width: maxWidth, height: font.lineHeight) /// Size for 1 line
        let height = title.rectWithConstrainedSize(size, font: font).height.rounded(.up)
        return (height * 3) + 20
    }

    private func setupView() {
        addViewsForAutolayout(views: [thumbnail, title, subtitle])
        thumbnail.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        thumbnail.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        thumbnail.widthAnchor.constraint(equalToConstant: 35).isActive = true
        thumbnail.heightAnchor.constraint(equalToConstant: 35).isActive = true

        title.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 10).isActive = true
        title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10).isActive = true
        title.topAnchor.constraint(equalTo: thumbnail.topAnchor).isActive = true

        subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor).isActive = true
        subtitle.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10).isActive = true
        subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3).isActive = true
    }

    @objc private func tapped() {
        guard let action = item?.action else {
            print("Action is not defined for this list item")
            return
        }
        guard let selected = selected else { return }
        selected(item?.title, action)
    }

    private func setupAction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }
}

class ListTemplateView: UIView {
    static var headerFont = UIFont(name: "Helvetica", size: 15) ?? UIFont.systemFont(ofSize: 15)
    static var imageHeight: CGFloat = 100
    static var textHeight: CGFloat = 30
    static var buttonHeight: CGFloat = 40

    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        return stackView
    }()

    let elementStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 1
        return stackView
    }()

    let headerImage: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 0
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    let headerText: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = ListTemplateView.headerFont
        label.backgroundColor = .white
        label.textAlignment = .center
        label.textColor = UIColor(red: 32, green: 31, blue: 31)
        return label
    }()

    var actionButtons = [UIButton]()
    var listItems = [ListTemplateElementView]()

    lazy var headerImageHeight = self.headerImage.heightAnchor.constraint(equalToConstant: ListTemplateView.imageHeight)
    lazy var headerTextHeight = self.headerText.heightAnchor.constraint(equalToConstant: ListTemplateView.textHeight)

    var item: ListTemplate?
    var selected: ((_ text: String?, _ action: ListTemplate.Action) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupElements()
        setupButtons()
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: ListTemplate) {
        updateHeaderImage(item.headerImgSrc)
        updateHeaderText(item.headerText)
        updateButtons(item.buttons)
        updateListItems(item.elements)
        self.item = item
        layoutIfNeeded()
    }

    private func updateHeaderImage(_ urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            headerImageHeight.constant = 0
            return
        }
        headerImageHeight.constant = ListTemplateView.imageHeight
        headerImage.kf.setImage(with: url)
    }

    private func updateHeaderText(_ text: String?) {
        guard let text = text else {
            headerTextHeight.constant = 0
            return
        }
        headerTextHeight.constant = ListTemplateView.textHeight
        headerText.text = text
    }

    private func updateButtons(_ buttons: [ListTemplate.Button]?) {
        guard let buttons = buttons else {
            actionButtons.enumerated().forEach { $1.isHidden = true }
            return
        }
        if buttons.count > actionButtons.count {
            print("Number of buttons are >8. Only first 8 will be shown")
        }
        actionButtons.enumerated().forEach {
            if $0 >= buttons.count { $1.isHidden = true } else {
                $1.isHidden = false
                $1.setTitle(buttons[$0].name, for: .normal)
            }
        }
    }

    private func updateListItems(_ elements: [ListTemplate.Element]?) {
        guard let elements = elements else {
            listItems.enumerated().forEach { $1.isHidden = true }
            return
        }
        if elements.count > listItems.count {
            print("Number of elements are >8. Only first 8 will be shown")
        }
        listItems.enumerated().forEach {
            if $0 >= elements.count { $1.isHidden = true } else {
                $1.isHidden = false
                $1.update(item: elements[$0])
            }
        }
    }

    static func rowHeight(template: ListTemplate) -> CGFloat {
        var height: CGFloat = 0
        height += template.headerImgSrc != nil ? imageHeight : CGFloat(0)
        height += template.headerText != nil ? textHeight : CGFloat(0)
        let elementCount = min(8, template.elements?.count ?? 0)
        height += CGFloat(elementCount) * ListTemplateElementView.height()
        let buttonCount = min(8, template.buttons?.count ?? 0)
        height += CGFloat(buttonCount) * buttonHeight
        let spacing = min(8, template.elements?.count ?? 0) + min(8, template.buttons?.count ?? 0)
        return height + CGFloat(spacing)
    }

    @objc private func buttonSelected(_ sender: UIButton) {
        let index = sender.tag
        guard let buttons = item?.buttons else { return }
        let selectedButton = buttons[index]

        guard let action = selectedButton.action else {
            print("Action is not defined for this list item")
            return
        }
        guard let selected = selected else { return }
        selected(selectedButton.name, action)
    }

    private func setupButtons() {
        actionButtons = (0 ... 7).map {
            let button = UIButton()
            button.setTitleColor(UIColor(red: 85, green: 83, blue: 183), for: .normal)
            button.setFont(font: UIFont.font(.bold(size: 15.0)))
            button.setTitle("Button", for: .normal)
            button.addTarget(self, action: #selector(buttonSelected(_:)), for: .touchUpInside)
            button.titleLabel?.numberOfLines = 1
            button.tag = $0
            button.backgroundColor = .white
            button.layoutIfNeeded()
            return button
        }
    }

    private func setupElements() {
        listItems = (0 ... 7).map {
            let item = ListTemplateElementView()
            item.tag = $0
            item.backgroundColor = .white
            item.selected = { [weak self] defaultText, action in
                guard let weakSelf = self, let selected = weakSelf.selected else { return }
                selected(defaultText, action)
            }
            return item
        }
    }

    private func setupConstraints() {
        actionButtons.forEach {
            buttonStackView.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalToConstant: ListTemplateView.buttonHeight).isActive = true
        }
        listItems.forEach {
            elementStackView.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalToConstant: ListTemplateElementView.height()).isActive = true
        }
        backgroundColor = .lightGray
        addViewsForAutolayout(views: [headerImage, headerText, elementStackView, buttonStackView])

        headerImage.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerImage.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        headerImage.topAnchor.constraint(equalTo: topAnchor).isActive = true
        headerImageHeight.isActive = true

        headerText.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        headerText.topAnchor.constraint(equalTo: headerImage.bottomAnchor).isActive = true
        headerText.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerText.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        headerTextHeight.isActive = true

        elementStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        elementStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        elementStackView.topAnchor.constraint(equalTo: headerText.bottomAnchor, constant: 1).isActive = true

        buttonStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        buttonStackView.topAnchor.constraint(equalTo: elementStackView.bottomAnchor, constant: 1).isActive = true
    }
}
