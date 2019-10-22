//
//  Geocode.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import CoreLocation
import Foundation

public final class Geocode: CustomStringConvertible {
    static let defaultFormattedAddress = ""

    var displayName: String = defaultFormattedAddress
    var formattedAddress: String = defaultFormattedAddress
    var placeIdentifier: String = ""
    var location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var addressComponents = [[String: AnyObject]]()

    public required init(coordinates: CLLocationCoordinate2D) {
        location.latitude = coordinates.latitude
        location.longitude = coordinates.longitude
    }

    public var description: String {
        return "Geocode: \n displayName: \(displayName), \n formatted address: \(formattedAddress), \n placeIdentifier: \(placeIdentifier),  \n location: \(location)"
    }
}
