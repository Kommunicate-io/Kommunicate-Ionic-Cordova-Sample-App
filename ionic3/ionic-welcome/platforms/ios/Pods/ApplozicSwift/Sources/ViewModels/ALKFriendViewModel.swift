//
//  FriendViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

public protocol ALKContactProtocol {
    var friendUUID: String? { get }
    var friendMood: String? { get }
    var friendProfileName: String? { get }
    var friendDisplayImgURL: URL? { get }
}

open class ALKFriendViewModel {
    var friendUUID: String?
    var friendProfileName: String?
    var friendFirstName: String?
    var friendLastName: String?
    var friendEmail: String?
    var friendMood: String?
    var friendPhoneNumber: String?
    var friendDisplayImgURL: URL?
    var friendMoodExpiredAt: NSNumber?
    var isSelected: Bool = false

    init(identity: ALKContactProtocol) {
        friendUUID = identity.friendUUID
        friendProfileName = identity.friendProfileName
        if let friendDisplayImgURL = identity.friendDisplayImgURL {
            self.friendDisplayImgURL = friendDisplayImgURL
        } else {
            friendDisplayImgURL = URL(fileURLWithPath: "placeholder")
        }
    }

    // MARK: - Get

    func getFriendDisplayName() -> String {
        return friendProfileName ?? "No Name"
    }

    func getFriendID() -> String {
        return friendUUID!
    }

    func getFriendDisplayImgURL() -> URL {
        return friendDisplayImgURL!
    }

    func getIsSelected() -> Bool {
        return isSelected
    }

    // MARK: - Set

    func setIsSelected(select: Bool) {
        isSelected = select
    }
}
