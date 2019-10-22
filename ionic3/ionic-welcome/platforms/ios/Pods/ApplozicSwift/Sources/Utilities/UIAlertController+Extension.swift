//
//  UIAlertController+Extension.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension UIAlertController {
    static func makeCancelDiscardAlert(title: String, message: String, cancelTitle: String, discardTitle: String, discardAction: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelButton = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        let discardButton = UIAlertAction(title: discardTitle,
                                          style: .destructive,
                                          handler: { _ in
                                              discardAction()
        })
        alert.addAction(cancelButton)
        alert.addAction(discardButton)
        return alert
    }

    // swiftlint:disable:next function_parameter_count
    static func presentDiscardAlert(onPresenter presenter: UIViewController, alertTitle: String, alertMessage: String, cancelTitle: String, discardTitle: String, onlyForCondition condition: () -> Bool, lastAction: @escaping () -> Void) {
        if condition() {
            let alert = makeCancelDiscardAlert(title: alertTitle,
                                               message: alertMessage,
                                               cancelTitle: cancelTitle,
                                               discardTitle: discardTitle,
                                               discardAction: {
                                                   lastAction()
            })
            presenter.present(alert, animated: true, completion: nil)
        } else {
            lastAction()
        }
    }
}
