//
//  BeaconHandlingService.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import CoreLocation

class BeaconHandlingService {
    
    private init() { }
    
    static var shared = BeaconHandlingService()
    
    public func install(iBeacon beacon: CLBeacon, at location: CLLocationCoordinate2D) {
        //TODO Call API with Beacon and Location data
    }
    
    public func retrieve(iBeacon beacon: CLBeacon) {
        //TODO Call API with beacon data
    }
    
}
