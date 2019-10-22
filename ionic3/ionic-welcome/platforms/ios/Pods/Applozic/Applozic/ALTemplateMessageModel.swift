//
//  ALTemplateMessageModel.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import Foundation

@objc open class ALTemplateMessageModel: NSObject {

    /// Should be a unique identifier.
    @objc open var identifier: String

    /// Text to display.
    @objc  open var text: String

    /// If not set and `sendMessageOnSelection` is true
    /// then the value of `text` will be used to send the message.
    @objc  open var messageToSend: String?

    /// If true then the template will be shown
    /// irrespective of the message type of last message.
   @objc   open var showInAllCases: Bool = true

    @objc  open var onlyShowWhenLastMessageIsText: Bool = false
    @objc  open var onlyShowWhenLastMessageIsImage: Bool = false
   @objc   open var onlyShowWhenLastMessageIsVideo: Bool = false

    /// If set to false then the message will not be sent.
   @objc   open var sendMessageOnSelection: Bool = true

    @objc  public init(identifier: String, text: String) {
        self.identifier = identifier
        self.text = text
    }
}

extension ALTemplateMessageModel {

    /// Json will be parsed and mapped to the model.
    public convenience init?(json: [String: Any]) {
        guard let identifier = json["identifier"] as? String,
            let text = json["text"] as? String
            else {
                return nil
        }
        self.init(identifier: identifier, text: text)

        if let messageToSend = json["messageToSend"] as? String {
            self.messageToSend = messageToSend
        }
        if let sendMessageOnSelection = json["sendMessageOnSelection"] as? Bool {
            self.sendMessageOnSelection = sendMessageOnSelection
        }
    }
}
