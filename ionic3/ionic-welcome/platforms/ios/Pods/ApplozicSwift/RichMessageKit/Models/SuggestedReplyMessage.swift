//
//  QuickReplyModel.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 05/02/19.
//

import Foundation

public struct SuggestedReplyMessage {
    /// Title to be displayed in suggested replies
    public var title: [String]

    /// Reply that should be given when title is clicked
    /// If nil, then title will be used as reply
    public var reply: [String?]

    public var message: Message
}
