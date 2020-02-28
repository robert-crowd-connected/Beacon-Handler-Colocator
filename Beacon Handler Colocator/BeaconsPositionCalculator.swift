//
//  BeaconsPositionCalculator.swift
//  Beacon Handler Colocator
//
//  Created by TCode on 28/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import CoreLocation
import Foundation

class BeaconsPositionCalculator {
    
    static func calculateClosestBeaconAndNoiseLevel(detectedBeacons: [CLBeacon]) -> (CLBeacon?, NoiseLevel) {
        var max = -100
        var intermediateClosestBeacon: CLBeacon? = nil
        
        var otherCloseBeacons = [NSNumber]()
        var otherVeryCloseBeacons = [NSNumber]()
        var allDifferentBeacons = [NSNumber]()
        
        for beacon in detectedBeacons {
            if beacon.rssi > max {
                intermediateClosestBeacon = beacon
                max = intermediateClosestBeacon!.rssi
            } else {
                if beacon.rssi == max && intermediateClosestBeacon != nil {
                    if intermediateClosestBeacon!.accuracy > beacon.accuracy {
                        intermediateClosestBeacon = beacon
                    }
                }
            }
        }
        
        for beacon in detectedBeacons {
            if !allDifferentBeacons.contains(beacon.minor) {
                allDifferentBeacons.append(beacon.minor)
            }
            if abs(beacon.rssi - intermediateClosestBeacon!.rssi) <= 20 && abs(beacon.accuracy - intermediateClosestBeacon!.accuracy) <= 0.075 {
                if !otherCloseBeacons.contains(beacon.minor) && intermediateClosestBeacon!.minor != beacon.minor {
                    otherCloseBeacons.append(beacon.minor)
                }
            }
            if abs(beacon.rssi - intermediateClosestBeacon!.rssi) <= 4 && abs(beacon.accuracy - intermediateClosestBeacon!.accuracy) <= 0.005 {
                if !otherVeryCloseBeacons.contains(beacon.minor) && intermediateClosestBeacon!.minor != beacon.minor {
                    otherVeryCloseBeacons.append(beacon.minor)
                }
            }
        }
        
        let noise = calculcateNoiseLevel(monitoredBeacons: allDifferentBeacons.count,          // up to 3 meters
                                         closeBeacons: otherCloseBeacons.count,                // up to 1 meter
                                         veryClosebeacons: otherVeryCloseBeacons.count)        // up to 0.5 meters
        
        return (intermediateClosestBeacon, noise)
    }
    
    static private func calculcateNoiseLevel(monitoredBeacons: Int, closeBeacons: Int, veryClosebeacons: Int) -> NoiseLevel {
        var noiseLevel = NoiseLevel.none
        
        if closeBeacons == 0 && veryClosebeacons == 0 {
            return noiseLevel
        } else {
            var noise = 0.75 * Double(veryClosebeacons) + 0.25 * Double(closeBeacons)
            if noise >= Double(monitoredBeacons / 2) {
                noise *= 1.5
            }
            
            if noise < 1 {
                noiseLevel = .weak
            } else if noise < 3 {
                noiseLevel = .medium
            } else if noise <= 8 {
                noiseLevel = .high
            } else {
                noiseLevel = .veryHigh
            }
            
            return noiseLevel
        }
    }
}
