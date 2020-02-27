//
//  ServerBeacon.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 27/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation

struct ServerBeacon {
    var id: String
    var lat: Double
    var lng: Double
    var alt: Double
    var surfaceId: String
    var beaconType: String
    var beaconState: String
}


// Sample
//   "id": "385dedc2-467f-47e2-9a39-e633571952f1:0000:0038",
//   "lat": 51.239640147917214,
//   "lng": -0.611962080001831,
//   "alt": 1,
//   "surfaceId": "5d165930-e663-4ef7-a750-659a39c7f147",
//   "beaconType": "bluetooth",
//   "beaconState": "ACTIVE"
