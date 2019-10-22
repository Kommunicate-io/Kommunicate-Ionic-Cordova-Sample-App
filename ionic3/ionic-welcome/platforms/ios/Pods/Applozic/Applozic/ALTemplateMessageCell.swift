//
//  ALTemplateMessageCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import UIKit

@objc open class ALTemplateMessageCell: UICollectionViewCell {

    public let textLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.white
        label.contentMode = .center
        label.numberOfLines = 1
        return label
    }()

    public let leftPadding: CGFloat = 5.0
    public let rightPadding: CGFloat = 5.0


    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {

        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10.0
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
        self.backgroundColor = UIColor.white
        
        // Set constaints
        for view in [textLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(view)
        }

        if #available(iOS 9.0, *) {
            textLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            textLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: leftPadding).isActive = true
            textLabel.widthAnchor.constraint(equalTo:self.widthAnchor , constant: leftPadding).isActive = true
            textLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: rightPadding).isActive = true
            textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        } else {
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: textLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 2),
                NSLayoutConstraint(item: textLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: -1),
                NSLayoutConstraint(item: textLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: textLabel, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: leftPadding),
                NSLayoutConstraint(item: textLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
                ])
        }
    }

    open func update(text: String) {
        textLabel.text = text
    }
}
