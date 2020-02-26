//
//  BeaconSessionType.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation

enum BeaconSessionType: String {
    case install = "Install"
    case retrieve = "Retrieve"
}


enum NoiseLevel: String {
    case none = "None"
    case weak = "Weak"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
}
