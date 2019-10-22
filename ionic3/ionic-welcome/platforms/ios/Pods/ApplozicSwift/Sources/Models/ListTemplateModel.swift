//
//  ListTemplate.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 18/02/19.
//

import Foundation

/// Use this instead of `ALKGenericListTemplate`
public struct ListTemplate: Codable {
    public let headerImgSrc: String?
    public let headerText: String?
    public let elements: [Element]?
    public let buttons: [Button]?

    public struct Element: Codable {
        public let imgSrc: String?
        public let title: String?
        public let description: String?
        public let action: Action?
    }

    public struct Button: Codable {
        public let name: String?
        public let action: Action?
    }

    public struct Action: Codable {
        public let url: String?
        public let type: String?
        public let text: String?
    }
}
