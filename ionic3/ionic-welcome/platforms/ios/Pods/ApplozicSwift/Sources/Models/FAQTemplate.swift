//
//  FAQTemplate.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 03/06/19.
//

import Foundation

public struct FAQTemplate: Codable {
    public let title: String?
    public let description: String?
    public let buttonLabel: String?
    public let buttons: [Button]?

    public struct Button: Codable {
        public let name: String
        public let type: String?
    }
}
