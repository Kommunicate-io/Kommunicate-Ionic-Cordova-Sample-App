//
//  ALKFriendPhotoPortalCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

// MARK: - ALKFriendPhotoPortalCell

final class ALKFriendPhotoPortalCell: ALKFriendPhotoCell {
    override func setupViews() {
        super.setupViews()
        let width = UIScreen.main.bounds.width
        photoView.widthAnchor.constraint(equalToConstant: width * 0.48).isActive = true
    }
}
