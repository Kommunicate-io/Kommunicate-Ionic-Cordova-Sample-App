//
//  ALKFriendContactCell.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Kingfisher
import UIKit

final class ALKFriendContactCell: UITableViewCell {
    @IBOutlet private var imgView: UIImageView!
    @IBOutlet private var lblName: UILabel!
    @IBOutlet private var lblMood: UILabel!
    @IBOutlet private var imgFriendIcon: UIImageView!

    private var placeHolder: UIImage? = {
        UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        setupUI()
    }

    private func setupUI() {
        imgFriendIcon.makeCircle()
    }

    func update(viewModel: ALKFriendViewModel, isExistingFriend: Bool = false) {
        setupAlpha(isGrayOut: isExistingFriend)
        setupSelectionStyle(isSelectable: isExistingFriend)
        setFriendName(name: viewModel.getFriendDisplayName())

        if let mood = viewModel.friendMood, !mood.isEmpty, let expireDate = viewModel.friendMoodExpiredAt {
            let currentDate = Date()
            let expireDate = Date(timeIntervalSince1970: TimeInterval(truncating: expireDate))
            if currentDate < expireDate {
                setMood(text: viewModel.friendMood)
            } else {
                setMood(text: "")
            }

        } else {
            setMood(text: "")
        }

        setupFriendProfilePhoto(imgURL: viewModel.getFriendDisplayImgURL())
        setupCheckmark(isSelect: viewModel.getIsSelected())
    }

    private func setupAlpha(isGrayOut: Bool) {
        if isGrayOut {
            imgFriendIcon.alpha = 0.3
            imgView.alpha = 0.3
            lblName.alpha = 0.3
            lblMood.alpha = 0.3
        } else {
            imgFriendIcon.alpha = 1.0
            imgView.alpha = 1.0
            lblName.alpha = 1.0
            lblMood.alpha = 1.0
        }
    }

    private func setupSelectionStyle(isSelectable: Bool) {
        selectionStyle = isSelectable ? .none : .default
    }

    private func setFriendName(name: String) {
        lblName.text = name
    }

    private func setMood(text: String?) {
        lblMood.text = text ?? ""
    }

    private func setupFriendProfilePhoto(imgURL: URL) {
        let resource = ImageResource(downloadURL: imgURL, cacheKey: imgURL.absoluteString)
        imgFriendIcon.kf.setImage(with: resource, placeholder: placeHolder)
    }

    private func setupCheckmark(isSelect: Bool) {
        imgView.image = isSelect ? UIImage(named: "icon_checked", in: Bundle.applozic, compatibleWith: nil) : nil
    }
}
