//
//  UIImaveView+Extension.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension UIImageView {
    func cropRedProfile() {
        layer.cornerRadius = 0.5 * bounds.size.width
        layer.borderColor = UIColor.color(Color.Border.main).cgColor
        layer.borderWidth = 0.5
        clipsToBounds = true
    }

    func uncropRedProfile(radius _: CGFloat? = nil) {
        layer.cornerRadius = 0
        layer.borderColor = UIColor.clear.cgColor
        layer.borderWidth = 0.0
        clipsToBounds = false
    }

    func makeCircle() {
        layer.cornerRadius = 0.5 * frame.size.width
        clipsToBounds = true
    }
}
