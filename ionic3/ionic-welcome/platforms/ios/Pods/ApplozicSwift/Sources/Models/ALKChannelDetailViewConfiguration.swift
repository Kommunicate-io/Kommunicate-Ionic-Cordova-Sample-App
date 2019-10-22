//
//  ALKChannelDetailViewConfiguration.swift
//  ApplozicSwift
//
//  Created by Sunil on 14/08/19.
//

import Foundation

/// A type that can be used to configure channel detail view like changing member name label color, title font etc.
public struct ALKChannelDetailViewConfiguration {
    /// Button Style for save and invite style
    public var button = Style(
        font: Font.normal(size: 15.0).font(),
        text: .white,
        background: UIColor.mainRed()
    )

    /// Participant text style
    public var participantHeaderTitle = Style(
        font: Font.normal(size: 15.0).font(),
        text: UIColor.mainRed()
    )

    /// Edit text view border color
    public var groupNameBorderColor = UIColor.red

    /// Profile edit lable style
    public var editLabel = Style(
        font: Font.normal(size: 15.0).font(),
        text: UIColor.black,
        background: UIColor.lineBreakerProfile()
    )

    /// Default group icon
    public var defaultGroupIcon = UIImage(named: "group_profile_picture", in: Bundle.applozic, compatibleWith: nil)

    /// Add member icon
    public var addMemberIcon = UIImage(named: "icon_add_people-1", in: Bundle.applozic, compatibleWith: nil)

    /// Add memberName text style
    public var memberName = Style(
        font: Font.normal(size: 15.0).font(),
        text: UIColor.mainRed()
    )
    /// Group name text style
    public var groupName = Style(
        font: Font.normal(size: 15.0).font(),
        text: UIColor.black
    )

    public init() {}
}
