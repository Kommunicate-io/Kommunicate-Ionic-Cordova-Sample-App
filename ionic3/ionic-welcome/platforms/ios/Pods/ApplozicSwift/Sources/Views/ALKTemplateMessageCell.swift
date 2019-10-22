//
//  ALKTemplateMessageCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import UIKit

open class ALKTemplateMessageCell: UICollectionViewCell {
    open var textLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.black
        label.contentMode = .center
        label.numberOfLines = 1
        label.font = Font.normal(size: 16.0).font()
        return label
    }()

    public let leftPadding: CGFloat = 5.0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        layer.masksToBounds = true
        layer.cornerRadius = 10.0
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray.cgColor
        backgroundColor = UIColor.clear
        addViewsForAutolayout(views: [textLabel])

        textLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftPadding).isActive = true
        textLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        textLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    open func update(text: String) {
        textLabel.text = text
    }
}
