//
//  ALKFriendNewChatCell.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Kingfisher
import UIKit

class ALKFriendNewChatCell: UITableViewCell {
    private var imgDisplay: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 16.5
        layer.backgroundColor = UIColor.clear.cgColor
        layer.masksToBounds = true
        return imv
    }()

    private var lblDisplayName: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .text(.black00)
        return label
    }()

    private var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .color(Color.Background.grayF1)
        return view
    }()

    weak var delegate: ALKFriendCellProtocol?
    var indexPath: IndexPath!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [imgDisplay, lblDisplayName, separatorView])

        // Image Display
        imgDisplay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 11).isActive = true
        imgDisplay.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        imgDisplay.heightAnchor.constraint(equalToConstant: 33).isActive = true
        imgDisplay.widthAnchor.constraint(equalTo: imgDisplay.heightAnchor).isActive = true

        // Label
        imgDisplay.trailingAnchor.constraint(equalTo: lblDisplayName.leadingAnchor, constant: -15).isActive = true
        contentView.trailingAnchor.constraint(greaterThanOrEqualTo: lblDisplayName.trailingAnchor, constant: 12).isActive = true
        lblDisplayName.centerYAnchor.constraint(equalTo: imgDisplay.centerYAnchor, constant: 2).isActive = true

        // Separator
        separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setFriendCellDelegate(cellDelegate: ALKFriendCellProtocol?, indexPath: IndexPath) {
        delegate = cellDelegate
        self.indexPath = indexPath
    }

    func update(friend: ALKContactProtocol) {
        // no actual data yet
        lblDisplayName.text = friend.friendProfileName

        if friend.friendProfileName == "Create Group" {
            imgDisplay.image = UIImage(named: "group_profile_picture-1", in: Bundle.applozic, compatibleWith: nil)
            return
        }

        // image
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let tempURL: URL = friend.friendDisplayImgURL {
            let resource = ImageResource(downloadURL: tempURL)
            imgDisplay.kf.setImage(with: resource, placeholder: placeHolder)

        } else {
            imgDisplay.image = placeHolder
        }
    }

    @IBAction func voipPress(_: Any) {
        delegate?.startVOIPWithFriend(atIndex: indexPath)
    }

    @IBAction func chatPress(_: Any) {
        delegate?.startChatWithFriend(atIndex: indexPath)
    }
}
