//
//  ALKChatBaseCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

open class ALKChatBaseCell<T>: ALKBaseCell<T>, Localizable {
    var localizedStringFileName: String!
    var showReport: Bool = false

    public func setLocalizedStringFileName(_ localizedStringFileName: String) {
        self.localizedStringFileName = localizedStringFileName
    }

    fileprivate weak var chatBar: ALKChatBar?

    lazy var longPressGesture: UILongPressGestureRecognizer = {
        UILongPressGestureRecognizer(target: self, action: #selector(showMenuController(withLongPress:)))
    }()

    var avatarTapped: (() -> Void)?

    /// Actions available on menu where callbacks
    /// needs to be send are defined here.
    enum MenuActionType {
        case reply
        case reportMessage
    }

    /// It will be invoked when one of the actions
    /// is selected.
    var menuAction: ((MenuActionType) -> Void)?

    func update(chatBar: ALKChatBar) {
        self.chatBar = chatBar
    }

    @objc func menuWillShow(_: Any) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.willShowMenuNotification, object: nil)
    }

    @objc func menuWillHide(_: Any) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.willHideMenuNotification, object: nil)

        if let chatBar = self.chatBar {
            chatBar.textView.overrideNextResponder = nil
        }
    }

    @objc func showMenuController(withLongPress sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            NotificationCenter.default.addObserver(self, selector: #selector(menuWillShow(_:)), name: UIMenuController.willShowMenuNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(menuWillHide(_:)), name: UIMenuController.willHideMenuNotification, object: nil)

            if let chatBar = self.chatBar, chatBar.textView.isFirstResponder {
                chatBar.textView.overrideNextResponder = contentView
            } else {
                _ = canBecomeFirstResponder
            }

            guard let gestureView = sender.view, let superView = sender.view?.superview else {
                return
            }

            let menuController = UIMenuController.shared

            guard !menuController.isMenuVisible, gestureView.canBecomeFirstResponder else {
                return
            }

            gestureView.becomeFirstResponder()

            var menus: [UIMenuItem] = []

            if let copyMenu = getCopyMenuItem(copyItem: self) {
                menus.append(copyMenu)
            }

            if let replyMenu = getReplyMenuItem(replyItem: self) {
                menus.append(replyMenu)
            }

            if showReport, let reportMessageMenu = getReportMessageItem(reportMessageItem: self) {
                menus.append(reportMessageMenu)
            }

            menuController.menuItems = menus
            menuController.setTargetRect(gestureView.frame, in: superView)
            menuController.setMenuVisible(true, animated: true)
        }
    }

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override func canPerformAction(_ action: Selector, withSender _: Any?) -> Bool {
        switch self {
        case let menuItem as ALKCopyMenuItemProtocol where action == menuItem.selector:
            return true
        case let menuItem as ALKReplyMenuItemProtocol where action == menuItem.selector:
            return true
        case let menuItem as ALKReportMessageMenuItemProtocol where action == menuItem.selector:
            return true
        default:
            return false
        }
    }

    func getCopyMenuItem(copyItem: Any) -> UIMenuItem? {
        guard let copyMenuItem = copyItem as? ALKCopyMenuItemProtocol else {
            return nil
        }
        let title = localizedString(forKey: "Copy", withDefaultValue: SystemMessage.LabelName.Copy, fileName: localizedStringFileName)
        let copyMenu = UIMenuItem(title: title, action: copyMenuItem.selector)
        return copyMenu
    }

    func getReplyMenuItem(replyItem: Any) -> UIMenuItem? {
        guard let replyMenuItem = replyItem as? ALKReplyMenuItemProtocol else {
            return nil
        }
        let title = localizedString(forKey: "Reply", withDefaultValue: SystemMessage.LabelName.Reply, fileName: localizedStringFileName)
        let replyMenu = UIMenuItem(title: title, action: replyMenuItem.selector)
        return replyMenu
    }

    func getReportMessageItem(reportMessageItem: Any) -> UIMenuItem? {
        guard let reportMessageMenuItem = reportMessageItem as? ALKReportMessageMenuItemProtocol else {
            return nil
        }
        let title = localizedString(forKey: "Report", withDefaultValue: SystemMessage.LabelName.Report, fileName: localizedStringFileName)
        let reportMessageMenu = UIMenuItem(title: title, action: reportMessageMenuItem.selector)
        return reportMessageMenu
    }
}

// MARK: - ALKCopyMenuItemProtocol

@objc protocol ALKCopyMenuItemProtocol {
    func menuCopy(_ sender: Any)
}

extension ALKCopyMenuItemProtocol {
    var selector: Selector {
        return #selector(menuCopy(_:))
    }
}

// MARK: - ALKReplyMenuItemProtocol

@objc protocol ALKReplyMenuItemProtocol {
    func menuReply(_ sender: Any)
}

extension ALKReplyMenuItemProtocol {
    var selector: Selector {
        return #selector(menuReply(_:))
    }
}

// MARK: - ALKReportMessageMenuItemProtocol

@objc protocol ALKReportMessageMenuItemProtocol {
    func menuReport(_ sender: Any)
}

extension ALKReportMessageMenuItemProtocol {
    var selector: Selector {
        return #selector(menuReport(_:))
    }
}
