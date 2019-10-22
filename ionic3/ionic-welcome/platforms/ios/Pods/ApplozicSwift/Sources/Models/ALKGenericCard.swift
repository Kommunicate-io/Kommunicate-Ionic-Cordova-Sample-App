//
//  ALKGenericCard.swift
//  Applozic
//
//  Created by Mukesh Thawani on 27/03/18.
//

import Foundation

public struct ALKGenericCardTemplate {
    public var cards: [ALKGenericCard]
    init(cards: [ALKGenericCard]) {
        self.cards = cards
    }
}

public struct ALKGenericCard: Codable {
    public let title: String
    public let subtitle: String
    public let imageUrl: URL?
    public let overlayText: String?
    public let description: String
    public let rating: Int?
    public struct Button: Codable {
        public let data: String
        public let name: String
        public let action: String
    }

    public let buttons: [Button]?
    private enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case imageUrl = "headerImageUrl"
        case overlayText
        case description
        case rating
        case buttons = "actions"
    }
}
