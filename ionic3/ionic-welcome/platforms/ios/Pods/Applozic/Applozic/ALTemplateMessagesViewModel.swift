//
//  ALTemplateMessagesViewModel.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import Foundation

@objc open class ALTemplateMessagesViewModel: NSObject {
    
    @objc  open var messageTemplates: [ALTemplateMessageModel]
    
    public var leftRightPadding: CGFloat = 46.0
    public var height: CGFloat = 40.0
    
    public var textFont = UIFont.init(name: "Helvetica", size: CGFloat(14))
    
    @objc  public init(messageTemplates: [ALTemplateMessageModel]) {
        self.messageTemplates = messageTemplates
    }
    
    @objc  open func getNumberOfItemsIn(section: Int) -> Int {
        return messageTemplates.count
    }
    
    @objc  open func getTextForItemAt(row: Int) -> String? {
        guard row >= 0 && row < messageTemplates.count else {
            return nil
        }
        return messageTemplates[row].text
    }
    
    @objc  open func getSizeForItemAt(row: Int) -> CGSize {
        guard row >= 0 && row < messageTemplates.count else {
            return CGSize(width: 0, height: 0)
        }
        
        let size = (messageTemplates[row].text as NSString).size(withAttributes: [NSAttributedString.Key.font: textFont!])
        let newSize = CGSize(width: +size.width+leftRightPadding, height: height)
        return newSize
    }
    
    open func getTemplateForItemAt(row: Int) -> String? {
        guard row >= 0 && row < messageTemplates.count else {
            return nil
        }
        return messageTemplates[row].identifier
    }
    
    @objc  open func updateLast(message: ALMessage) {
        // Use last message to check the message type and to see if it's receiver's or sender's message
    }
    
}
