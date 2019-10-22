//
//  ALKConfigurable.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 13/06/18.
//

import Foundation

public protocol ALKConfigurable {
    var configuration: ALKConfiguration! { get }
    init(configuration: ALKConfiguration)
}
