//
//  ALPushNotificationHandler.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Applozic
import Foundation

public class ALKPushNotificationHandler: Localizable {
    public static let shared = ALKPushNotificationHandler()
    var navVC: UINavigationController?

    var contactId: String?
    var groupId: NSNumber?
    var conversationId: NSNumber?
    var title: String = ""
    var configuration: ALKConfiguration!

    private var alContact: ALContact? {
        let alContactDbService = ALContactDBService()
        guard let alContact = alContactDbService.loadContact(byKey: "userId", value: self.contactId) else {
            return nil
        }
        return alContact
    }

    private var alChannel: ALChannel? {
        let alChannelService = ALChannelService()

        // TODO: This is a workaround as other method uses closure.
        // Later replace this with:
        // alChannelService.getChannelInformation(, orClientChannelKey: , withCompletion: )
        guard let alChannel = alChannelService.getChannelByKey(self.groupId) else {
            return nil
        }
        return alChannel
    }

    public func dataConnectionNotificationHandlerWith(_ configuration: ALKConfiguration) {
        self.configuration = configuration

        // No need to add removeObserver() as it is present in pushAssist.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "showNotificationAndLaunchChat"), object: nil, queue: nil, using: { [weak self] notification in
            print("launch chat push notification received")
            self?.contactId = nil
            self?.groupId = nil
            self?.title = ""
            self?.conversationId = nil
            // Todo: Handle group

            guard let weakSelf = self, let object = notification.object as? String else { return }
            let components = object.components(separatedBy: ":")

            let noNameMessage = weakSelf.localizedString(forKey: "NoNameMessage", withDefaultValue: SystemMessage.NoData.NoName, fileName: configuration.localizedStringFileName)

            if components.count > 2 {
                guard let componentElement = Int(components[1]) else { return }
                let id = NSNumber(integerLiteral: componentElement)
                weakSelf.groupId = id
                guard let alChannel = weakSelf.alChannel, let name = alChannel.name else { return }
                weakSelf.title = name
            } else if components.count == 2 {
                guard let conversationComponent = Int(components[1]) else { return }
                weakSelf.conversationId = NSNumber(integerLiteral: conversationComponent)
                weakSelf.contactId = components[0]
                guard let alContact = weakSelf.alContact else { return }
                weakSelf.title = alContact.getDisplayName() ?? noNameMessage
            } else {
                weakSelf.contactId = object
                guard let alContact = weakSelf.alContact else { return }
                let displayName = alContact.getDisplayName() ?? noNameMessage
                weakSelf.title = displayName
            }

            guard let userInfo = notification.userInfo as? [String: Any], let state = userInfo["updateUI"] as? NSNumber else { return }

            switch state {
            case NSNumber(value: APP_STATE_ACTIVE.rawValue):
                guard let userInfo = notification.userInfo, let alertValue = userInfo["alertValue"] as? String else {
                    return
                }
                // TODO: FIX HERE. USE conversationId also.
                ALUtilityClass.thirdDisplayNotificationTS(alertValue, andForContactId: weakSelf.contactId, withGroupId: weakSelf.groupId, completionHandler: {
                    _ in
                    weakSelf.notificationTapped(userId: weakSelf.contactId, groupId: weakSelf.groupId)

                })
            default:
                weakSelf.launchIndividualChatWith(userId: weakSelf.contactId, groupId: weakSelf.groupId)
            }
        })
    }

    func launchIndividualChatWith(userId: String?, groupId: NSNumber?) {
        NSLog("Called via notification and user id is: ", userId ?? "Not Present")

        let messagesVC = ALKConversationListViewController(configuration: configuration)
        messagesVC.contactId = userId
        messagesVC.channelKey = groupId
        messagesVC.conversationId = conversationId

        let pushAssistant = ALPushAssist()
        let topVC = pushAssistant.topViewController
        let nav = ALKBaseNavigationViewController(rootViewController: messagesVC)
        navVC?.modalTransitionStyle = .crossDissolve
        topVC?.present(nav, animated: true, completion: nil)
    }

    func notificationTapped(userId: String?, groupId: NSNumber?) {
        launchIndividualChatWith(userId: userId, groupId: groupId)
    }
}
