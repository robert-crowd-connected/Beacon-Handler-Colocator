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
        serverBeaconsService = UpdatingServerBeaconsService.shared
    }
    
    static var shared = BeaconHandlingService()
    
    private var serverBeaconsService: UpdatingServerBeaconsService!
    
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
    
    public func install(iBeacon beacon: CLBeacon, at location: CLLocationCoordinate2D, completion: @escaping (Bool, String?) -> Void) {
        let serverBeacon = ServerBeacon(id: composeBeaconID(region: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor)),
                                        lat: location.latitude,
                                        lng: location.longitude,
                                        alt: 1,
                                        surfaceId: serverBeaconsService.surfaceId,
                                        beaconType: "IBEACON",
                                        beaconState: "ACTIVE")
        
        serverBeaconsService.putBeacon(beacon: serverBeacon) { success, errorMessage in
            if success {
                self.installSoundEffect?.play()
                self.addBeaconInHistoric(actionType: .install, region: beacon.uuid.uuidString, major: beacon.major, minor: beacon.minor, coordinates: location)
                completion(true, errorMessage)
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    public func retrieve(iBeacon beacon: CLBeacon, completion: @escaping (Bool, String?) -> Void) {
        retrieveBeaconManual(regionUUID: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor)) { success, errorMessage in
             completion(success, errorMessage)
        }
    }
    
    public func retrieveBeaconManual(regionUUID: String, major: Int, minor: Int, completion: @escaping (Bool, String?) -> Void) {
        let beaconId = composeBeaconID(region: regionUUID, major: major, minor: minor)
        
        serverBeaconsService.getBeacon(withId: beaconId) { success, errorMessage, serverBeacon in
            if success {
                if var updatedServerBeacon = serverBeacon {
                    updatedServerBeacon.beaconState = "RETRIEVED"
                    self.serverBeaconsService.updateBeacon(beacon: updatedServerBeacon) { success, updateErrorMessage in
                        if success {
                            self.retrieveSoundEffect?.play()
                            self.addBeaconInHistoric(actionType: .retrieve, region: regionUUID, major: NSNumber(value: major), minor: NSNumber(value: minor))
                            completion(true, nil)
                        } else {
                            completion(false, updateErrorMessage)
                        }
                    }
                } else {
                    completion(false, errorMessage)
                }
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    private func composeBeaconID(region: String, major: Int, minor: Int) -> String {
        let fullMajor = String(format: "%04d", major)
        let fullMinor = String(format: "%04d", minor)
        return "\(region.lowercased()):\(fullMajor):\(fullMinor)"
    }
    
    // Historic
    public func getActionsHistoric() -> [BeaconAction] {
        return actionsHistoric
    }
    
    private func addBeaconInHistoric(actionType: BeaconSessionType, region: String, major: NSNumber, minor: NSNumber, coordinates: CLLocationCoordinate2D? = nil) {
        let action = BeaconAction(type: actionType, region: region, major: Int(truncating: major), minor: Int(truncating: minor), coordinates: coordinates)
        actionsHistoric.append(action)
    }
}
