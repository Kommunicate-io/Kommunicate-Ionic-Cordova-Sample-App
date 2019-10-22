//
//  ALKChatBarConfiguration.swift
//  ApplozicSwift
//
//  Created by Mukesh on 02/07/19.
//

import Foundation

/// Types attachment that a user can send
public enum AttachmentType: CaseIterable, Equatable {
    case contact
    case camera
    case gallery
    case video
    case location
}

/// A type that can be used to configure chat bar items
/// like attachment icons and their visibility.
public struct ALKChatBarConfiguration {
    /// A combination of different `AttachmentType`s we support.
    public enum AttachmentOptions {
        case all
        case none
        case some([AttachmentType])
    }

    /// Use this to set the `AttachmentOptions` you want to show.
    /// By default it is set to `all`.
    public var optionsToShow: AttachmentOptions = .all

    private(set) var attachmentIcons: [AttachmentType: UIImage?] = {
        // This way we'll get an error when we have added a
        // new option but its icon is not present.
        var icons = [AttachmentType: UIImage?]()
        for option in AttachmentType.allCases {
            switch option {
            case .contact:
                icons[.contact] = UIImage(named: "contactShare", in: Bundle.applozic, compatibleWith: nil)
            case .camera:
                icons[.camera] = UIImage(named: "photo", in: Bundle.applozic, compatibleWith: nil)
            case .gallery:
                icons[.gallery] = UIImage(named: "gallery", in: Bundle.applozic, compatibleWith: nil)
            case .video:
                icons[.video] = UIImage(named: "video", in: Bundle.applozic, compatibleWith: nil)
            case .location:
                icons[.location] = UIImage(named: "location_new", in: Bundle.applozic, compatibleWith: nil)
            }
        }
        return icons
    }()

    /// Sets the icon for the given attachment type.
    ///
    /// - Parameters:
    ///   - icon: The image to use for specific type.
    ///   - type: The type(`AttachmentType`) that uses the specified image.
    public mutating func set(
        attachmentIcon icon: UIImage?,
        for type: AttachmentType
    ) {
        guard let icon = icon else { return }
        attachmentIcons[type] = icon
    }
}

extension ALKChatBarConfiguration.AttachmentOptions: Equatable {
    public static func == (lhs: ALKChatBarConfiguration.AttachmentOptions, rhs: ALKChatBarConfiguration.AttachmentOptions) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.all, .all):
            return true
        case let (.some(l), .some(r)):
            return l == r
        case (.all, _):
            return false
        case(.some, _):
            return false
        case(.none, _):
            return false
        }
    }
}
