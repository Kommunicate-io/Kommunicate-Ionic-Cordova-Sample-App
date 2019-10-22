//
//  LocationPreviewViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import CoreLocation
import Foundation

let defaultMapZoomLevel: Float = 16
let defaultLatitude = 13.765221
let defaultLongitude = 100.538338
let minimumMapZoomLevel: Float = 3
let maxmimumMapZoomLevel: Float = 34

struct ALKLocationPreviewViewModel: Localizable {
    fileprivate var localizedStringFileName: String!

    private var address: String
    private var coor: CLLocationCoordinate2D

    var addressText: String {
        return address
    }

    var coordinate: CLLocationCoordinate2D {
        return coor
    }

    var isReady: Bool {
        let unspecifiedLocationMsg = localizedString(forKey: "UnspecifiedLocation", withDefaultValue: SystemMessage.UIError.unspecifiedLocation, fileName: localizedStringFileName)
        return addressText != unspecifiedLocationMsg
    }

    init(geocode: Geocode, localizedStringFileName: String) {
        self.init(addressText: geocode.displayName, coor: geocode.location, localizedStringFileName: localizedStringFileName)
    }

    init(addressText: String, coor: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: defaultLatitude, longitude: defaultLongitude), localizedStringFileName: String) {
        address = addressText
        self.coor = coor
        self.localizedStringFileName = localizedStringFileName
    }
}
