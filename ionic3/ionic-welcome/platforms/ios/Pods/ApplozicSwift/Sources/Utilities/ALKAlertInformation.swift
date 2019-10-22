//
//  AlertInformation.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

struct ALKAlertText {
    struct Title {
        static let Discard = NSLocalizedString("DiscardChangeTitle", value: SystemMessage.LabelName.DiscardChangeTitle, comment: "")
    }

    struct Message {
        static let Discard = NSLocalizedString("DiscardChangeMessage", value: SystemMessage.Warning.DiscardChange, comment: "")
    }
}

enum ALKAlertInformation {
    case discardChange

    var title: String {
        switch self {
        case .discardChange:
            return ALKAlertText.Title.Discard
        }
    }

    var message: String {
        switch self {
        case .discardChange:
            return ALKAlertText.Message.Discard
        }
    }
}
