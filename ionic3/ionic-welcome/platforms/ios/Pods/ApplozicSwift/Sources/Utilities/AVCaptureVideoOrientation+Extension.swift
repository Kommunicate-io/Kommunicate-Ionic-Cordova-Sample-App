//
//  AVCaptureVideoOrientation+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import AVFoundation
import UIKit

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        }
    }

    init(ui: UIInterfaceOrientation) {
        switch ui {
        case .landscapeRight: self = .landscapeRight
        case .landscapeLeft: self = .landscapeLeft
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: self = .portrait
        }
    }

    init?(orientation: UIDeviceOrientation) {
        switch orientation {
        case .landscapeRight: self = .landscapeLeft
        case .landscapeLeft: self = .landscapeRight
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        default:
            return nil
        }
    }
}
