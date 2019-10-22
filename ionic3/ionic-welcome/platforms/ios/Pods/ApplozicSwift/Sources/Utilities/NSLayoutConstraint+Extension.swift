//
//  NSLayoutConstraint+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 11/12/17.
//

import Foundation

extension NSLayoutDimension {
    func constraintEqualToAnchor(constant: CGFloat, identifier: String) -> NSLayoutConstraint {
        let constraint = self.constraint(equalToConstant: constant)
        constraint.identifier = identifier
        return constraint
    }
}
