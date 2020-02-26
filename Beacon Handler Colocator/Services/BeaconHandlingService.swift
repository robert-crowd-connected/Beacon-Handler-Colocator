//
//  BeaconHandlingService.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import AVFoundation
import Foundation
import CoreLocation

class BeaconHandlingService {
    
    private init() {
        configureSoundEffects()
    }
    
    static var shared = BeaconHandlingService()
    
    private var actionsHistoric = [BeaconAction]()
    
    private var installSoundEffect: AVAudioPlayer?
    private var retrieveSoundEffect: AVAudioPlayer?
    
    private func configureSoundEffects() {
        let pathInstall = Bundle.main.path(forResource: "installBeacon.mp3", ofType:nil)!
        let urlInstall = URL(fileURLWithPath: pathInstall)

        do {
            installSoundEffect = try AVAudioPlayer(contentsOf: urlInstall)
        } catch {
            // couldn't load file :(
        }

        let pathRetrieve = Bundle.main.path(forResource: "retrieveBeacon.mp3", ofType:nil)!
        let urlRetrieve = URL(fileURLWithPath: pathRetrieve)

        do {
            retrieveSoundEffect = try AVAudioPlayer(contentsOf: urlRetrieve)
        } catch {
            // couldn't load file :(
        }
    }
    
    public func install(iBeacon beacon: CLBeacon, at location: CLLocationCoordinate2D) {
        //TODO Call API with Beacon and Location data
        
        installSoundEffect?.play()
        addBeaconInHistoric(actionType: .install, region: beacon.uuid.uuidString, major: beacon.major, minor: beacon.minor, coordinates: location)
    }
    
    public func retrieve(iBeacon beacon: CLBeacon) {
        //TODO Call API with beacon data
        
        retrieveSoundEffect?.play()
        addBeaconInHistoric(actionType: .install, region: beacon.uuid.uuidString, major: beacon.major, minor: beacon.minor)
    }
    
    public func retrieveBeaconManual(regionUUID: String, major: Int, minor: Int) {
         //TODO Call API with beacon data
        
        retrieveSoundEffect?.play()
        addBeaconInHistoric(actionType: .install, region: regionUUID, major: NSNumber(value: major), minor: NSNumber(value: minor))
    }
    
    public func getActionsHistoric() -> [BeaconAction] {
        return actionsHistoric
    }
    
    private func addBeaconInHistoric(actionType: BeaconSessionType, region: String, major: NSNumber, minor: NSNumber, coordinates: CLLocationCoordinate2D? = nil) {
        let action = BeaconAction(type: actionType, region: region, major: Int(truncating: major), minor: Int(truncating: minor), coordinates: coordinates)
        actionsHistoric.append(action)
    }
}
