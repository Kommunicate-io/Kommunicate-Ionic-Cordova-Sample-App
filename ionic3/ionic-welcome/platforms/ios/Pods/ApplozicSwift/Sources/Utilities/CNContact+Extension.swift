//
//  CNContact+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 13/05/19.
//

import Contacts

extension CNContact {
    static func fetchContact(using filePath: String) -> CNContact? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fullPath = documentsURL.appendingPathComponent(filePath)
        guard
            let data = try? Data(contentsOf: fullPath),
            let contacts = try? CNContactVCardSerialization.contacts(with: data),
            !contacts.isEmpty
        else {
            return nil
        }
        return contacts[0]
    }
}
