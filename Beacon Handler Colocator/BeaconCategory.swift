//
//  BeaconCategory.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation

let kMajorValueStorageKey = "MAJORVALUESTORAGEKEY"
let kBeaconCattegoryStorageKey = "BEACONCATEGORYSTORAGEKEY"

public enum BeaconCategory: Int {
    case card = 0
    case battery = 1
    
    public var title: String {
        switch self {
        case .card: return "Card Beacons"
        case .battery: return "Battery beacons"
        }
    }
    
    public var regionID: String {
        switch self {
        case .card: return "1a9a515e-a845-467e-a313-3a8735f47514"
        case .battery: return "2c2d41fb-d4c5-4a4d-a49a-e8fd5c256293"
        }
    }
    
    public var regionUUID: UUID {
        return UUID(uuidString: self.regionID)!
    }
}
