//
//  UISearchBar+Extension.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

extension UISearchBar {
    func applySearchBarStyle() {
//        self.barTintColor             = SearchBarStyle.barTintColor
//        self.backgroundColor          = SearchBarStyle.backgroundColor
//        self.layer.borderWidth        = SearchBarStyle.borderWidth
//        self.layer.borderColor        = SearchBarStyle.borderColor
        backgroundImage = nil
    }

    static func createAXSearchBar(placeholder: String) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.applySearchBarStyle()
        searchBar.placeholder = placeholder
        return searchBar
    }

    var textField: UITextField? {
        func findInView(_ view: UIView) -> UITextField? {
            for subview in view.subviews {
                print("checking \(subview)")
                if let textField = subview as? UITextField {
                    return textField
                } else if let viewPresent = findInView(subview) {
                    return viewPresent
                }
            }
            return nil
        }

        return findInView(self)
    }
}
