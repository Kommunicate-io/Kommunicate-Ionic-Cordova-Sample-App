//
//  CLLocationManager+Extension.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationManager {
    static func initializeLocationManager(delegate: CLLocationManagerDelegate) -> CLLocationManager {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = delegate
        return manager
    }

    static func showLocationPermissionAlert(vc: UIViewController) {
        switch CLLocationManager.authorizationStatus() {
        case .restricted, .denied, .notDetermined:
            let alertTitle = NSLocalizedString("TurnOnLocationService", value: SystemMessage.Map.TurnOnLocationService, comment: "")
            let alertMessage = NSLocalizedString("LocationAlertMessage", value: SystemMessage.Map.LocationAlertMessage, comment: "")
            let alertController = UIAlertController(
                title: alertTitle,
                message: alertMessage,
                preferredStyle: .alert
            )

            let notNowTitle = NSLocalizedString("NotNow", value: SystemMessage.LabelName.NotNow, comment: "")
            let notNowAction = UIAlertAction(title: notNowTitle,
                                             style: .cancel,
                                             handler: nil)

            let settingsTitle = NSLocalizedString("Settings", value: SystemMessage.LabelName.Settings, comment: "")
            let openSettingAction = UIAlertAction(title: settingsTitle, style: .default) { _ in
                if let url = NSURL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.openURL(url as URL)
                }
            }

            alertController.addAction(notNowAction)
            alertController.addAction(openSettingAction)
            vc.present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }

    func requestMyLocation() {
        if #available(iOS 9.0, *) {
            self.requestLocation()
        } else {
            startUpdatingLocation()
        }
    }

    func stopMyLocationRequest() {
        stopUpdatingLocation()
    }
}
