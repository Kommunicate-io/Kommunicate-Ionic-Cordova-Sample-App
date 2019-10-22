//
//  UITextField+Extension.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension UITextField {
    func trimmedWhitespaceText() -> String {
        if let text = self.text {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}
