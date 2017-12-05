//
//  PlacesData.swift
//  Lisbon Travel App
//
//  Created by Kelsey Bishop on 11/28/17.
//  Copyright © 2017 Kelsey Bishop. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class PlacesData: NSObject, MKAnnotation {
    var placeName: String
    var address: String
    var postingUserID: String
    var coordinate: CLLocationCoordinate2D
    var placeDocumentID: String
    var placeImage: String
    var placeDescription: String

    var title: String? {
        return placeName
    }

    var subtitle: String? {
        return address
    }

    init(placeName: String, address: String, coordinate: CLLocationCoordinate2D, postingUserID: String, placeDocumentID: String, placeImage: String, placeDescription: String) {
        self.placeName = placeName
        self.address = address
        self.coordinate = coordinate
        self.postingUserID = postingUserID
        self.placeDocumentID = placeDocumentID
        self.placeImage = placeImage
        self.placeDescription = placeDescription
    }
}

