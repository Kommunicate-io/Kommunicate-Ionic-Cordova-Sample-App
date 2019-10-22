//
//  UIStoryboard+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

protocol StoryboardIdentifiable {
    static var storyboardIdentifier: String { get }
}

extension StoryboardIdentifiable where Self: UIViewController {
    static var storyboardIdentifier: String {
        return String(describing: self)
    }
}

extension UIViewController: StoryboardIdentifiable {}

extension UIStoryboard {
    enum Storyboard: String {
        case main = "Main"
        case login = "Login"
        case mainMenu = "MainMenu"
        case imgCrop = "CropImg"
        case splashSC = "SplashScreen"
        case camera = "CustomCamera"
        case createGroupChat = "CreateGroupChat"
        case userSearch = "UserSearch"
        case chatTab = "ChatTab"
        case shareLocation = "ShareLocation"
        case previewLocation = "PreviewLocation"
        case previewImage = "PreviewImage"
        case conversation = "Conversation"
        case emailRegister = "EmailRegister"
        case emailSignIn = "EmailSignin"
        case setting = "Setting"
        case callsTab = "CallsTab"
        case video = "CustomVideoCapture"
        case picker = "CustomPicker"
        case mediaViewer = "MediaViewer"
        case mapView = "MapView"
    }

    convenience init(storyboard: Storyboard, bundle: Bundle? = nil) {
        self.init(name: storyboard.rawValue, bundle: bundle)
    }

    class func name(storyboard: Storyboard, bundle: Bundle? = nil) -> UIStoryboard {
        return UIStoryboard(name: storyboard.rawValue, bundle: bundle)
    }

    func instantiateViewController<T: UIViewController>() -> T where T: StoryboardIdentifiable {
        let optionalVC = instantiateViewController(withIdentifier: T.storyboardIdentifier)

        guard let vc = optionalVC as? T else {
            fatalError("Couldn't instantiate view controller with identifier \(T.storyboardIdentifier)")
        }

        return vc
    }
}
