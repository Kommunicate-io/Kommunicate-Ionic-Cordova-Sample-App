//
//  Bundle+Extension.swift
//  Pods
//
//  Created by Mukesh Thawani on 08/09/17.
//
//

import Foundation

extension Bundle {
    static var applozic: Bundle {
        return Bundle(for: ALKConversationListViewController.self)
    }
}
