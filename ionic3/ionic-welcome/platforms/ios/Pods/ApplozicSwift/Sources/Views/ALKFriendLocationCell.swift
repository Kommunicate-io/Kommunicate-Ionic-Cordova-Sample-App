//
//  ALKFriendLocationCell.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Kingfisher
import UIKit

final class ALKFriendLocationCell: ALKLocationCell {
    // MARK: - Declare Variables or Types

    // MARK: Environment in chat

    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.backgroundColor = UIColor.lightGray.cgColor
        layer.masksToBounds = true
        return imv
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        return label
    }()

    // MARK: - Lifecycle

    override func setupViews() {
        super.setupViews()

        // add view to contenview and setup constraint
        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel])

        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6.0).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 57.0).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -56.0).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 16.0).isActive = true

        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18.0).isActive = true
        avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0.0).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 9.0).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 37.0).isActive = true
        avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor).isActive = true

        bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6.0).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6.0).isActive = true
        bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10.0).isActive = true

        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 2.0).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2.0).isActive = true
    }

    override func setupStyle() {
        super.setupStyle()
        nameLabel.setStyle(ALKMessageStyle.displayName)
        if ALKMessageStyle.receivedBubble.style == .edge {
            bubbleView.backgroundColor = ALKMessageStyle.receivedBubble.color
            bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
        } else {
            bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            bubbleView.tintColor = ALKMessageStyle.receivedBubble.color
            bubbleView.backgroundColor = ALKMessageStyle.receivedBubble.color
        }
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        nameLabel.text = viewModel.displayName

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        return super.rowHeigh(viewModel: viewModel, width: width) + 34.0
    }
}
