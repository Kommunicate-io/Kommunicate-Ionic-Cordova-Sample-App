//
//  ALKConversationProfile.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 01/03/19.
//

import Foundation

/// This model is used in `ALKConversationNavBar`
///
/// It contains information to show title, subtitle and image at navigation bar.
struct ALKConversationProfile {
    var name: String = ""
    var imageUrl: String?
    var isBlocked: Bool = false
    var status: Status? // Required only for One-to-One chat.

    struct Status {
        let lastSeenAt: NSNumber?
        let isOnline: Bool

        init(isOnline: Bool, lastSeenAt: NSNumber?) {
            self.isOnline = isOnline
            self.lastSeenAt = lastSeenAt
        }
    }

    init() {}
}
