//
//  BeaconAnnotation.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class BeaconAnnotation : NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var beacon: CLBeacon
    var title: String!
    var subtitle: String!
    
    init(location coord:CLLocationCoordinate2D, beacon: CLBeacon) {
        self.coordinate = coord
        self.beacon = beacon
        self.title = "iBeacon"
        self.subtitle = "Major \(beacon.major), Minor \(beacon.minor)"
        super.init()
    }
}
