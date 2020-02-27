//
//  BeaconAction.swift
//  Beacon Handler Colocator
//
//  Created by TCode on 26/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import CoreLocation

class BeaconAction {
    public var actionType: BeaconSessionType
    public var regionUUID: String
    public var major: Int
    public var minor: Int
    public var coordinates: CLLocationCoordinate2D?
    
    public var timestamp: Date
    public var description: String
    
    public init(type: BeaconSessionType, region: String, major: Int, minor: Int, coordinates: CLLocationCoordinate2D?) {
        self.actionType = type
        self.regionUUID = region
        self.major = major
        self.minor = minor
        self.coordinates = coordinates
        
        self.timestamp = Date()
        self.description = "Major \(major)  Minor \(minor)  on  \(timestamp.description)"
    }
}
