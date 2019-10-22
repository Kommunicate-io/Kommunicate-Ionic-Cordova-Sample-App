//
//  ALChatBarTextView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

open class ALKChatBarTextView: UITextView {
    weak var overrideNextResponder: UIResponder?

    open override var next: UIResponder? {
        if let overrideNextResponder = self.overrideNextResponder {
            return overrideNextResponder
        }

        return super.next
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if overrideNextResponder != nil {
            return false
        }

        return super.canPerformAction(action, withSender: sender)
    }
}
