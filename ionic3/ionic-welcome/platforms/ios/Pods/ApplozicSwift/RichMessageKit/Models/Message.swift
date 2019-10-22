//
//  MessageModel.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 18/01/19.
//

import Foundation

/// Gives infomation about message status.
public enum MessageStatus {
    case pending
    case sent
    case delivered
    case read
}

/// It defines the properties that are used by cells to render views.
public struct Message {
    /// Text to be displayed as message.
    public var text: String?

    /// Indicates whether this method is at sender side or receiver side.
    ///
    /// Value For sender: 'true'. For receiver: 'false'.
    public var isMyMessage: Bool

    /// Time of message.
    public var time: String

    /// Display name of sender.
    ///
    /// - Important: Mandatory for received message.
    public var displayName: String?

    /// Status of message whether it is in pending/sent/delivered/read state.
    ///
    /// - Important: Mandatory for sent message.
    public var status: MessageStatus?

    /// Image url of sender.
    public var imageURL: URL?
}
