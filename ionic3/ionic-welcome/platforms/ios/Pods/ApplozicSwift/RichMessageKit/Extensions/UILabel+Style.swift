//
//  UILabel+Extension.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 21/01/19.
//

import UIKit

extension UILabel {
    func setStyle(_ style: Style) {
        font = style.font
        textColor = style.text
        backgroundColor = style.background
    }
}
