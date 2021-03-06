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
import SwiftSpinner

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
    private var errorSoundEffect: AVAudioPlayer?
    
    private func configureSoundEffects() {
        let pathInstall = Bundle.main.path(forResource: "installBeacon.mp3", ofType: nil)!
        let urlInstall = URL(fileURLWithPath: pathInstall)
        do {
            installSoundEffect = try AVAudioPlayer(contentsOf: urlInstall)
        } catch { }

        let pathRetrieve = Bundle.main.path(forResource: "retrieveBeacon.mp3", ofType:nil)!
        let urlRetrieve = URL(fileURLWithPath: pathRetrieve)
        do {
            retrieveSoundEffect = try AVAudioPlayer(contentsOf: urlRetrieve)
        } catch { }
        
        let pathError = Bundle.main.path(forResource: "error.mp3", ofType:nil)!
        let urlError = URL(fileURLWithPath: pathError)
        do {
            errorSoundEffect = try AVAudioPlayer(contentsOf: urlError)
        } catch { }
    }
    
    public func install(iBeacon beacon: CLBeacon, at location: CLLocationCoordinate2D, completion: @escaping (Bool, String?) -> Void) {
        guard let surface = SurfaceService.shared.surfaceId else {
            completion(false, "Cannot find the surface ID for installation")
            return
        }
        
        SwiftSpinner.show("Installing iBeacon " + String(format: "%04d", Int(truncating: beacon.minor)))
        let beaconId = composeBeaconID(region: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor))
        let serverBeacon = ServerBeacon(id: beaconId,
                                        lat: location.latitude,
                                        lng: location.longitude,
                                        alt: 1,
                                        surfaceId: surface,
                                        beaconType: "IBEACON",
                                        beaconState: "ACTIVE")
        
        serverBeaconsService.putBeacon(beacon: serverBeacon) { success, errorMessage in
            SwiftSpinner.hide()
            if success {
                self.installSoundEffect?.play()
                self.addBeaconInHistoric(actionType: .install, region: beacon.uuid.uuidString, major: beacon.major, minor: beacon.minor, coordinates: location)
                completion(true, errorMessage)
            } else {
                self.errorSoundEffect?.play()
                completion(false, errorMessage)
            }
        }
    }
    
    public func install(iBeacon beacon: CLBeacon, nonGeoPosition position: CGPoint, completion: @escaping (Bool, String?) -> Void) {
        guard let surface = SurfaceService.shared.surfaceId else {
            completion(false, "Cannot find the surface ID for installation")
            return
        }
        
        SwiftSpinner.show("Installing iBeacon " + String(format: "%04d", Int(truncating: beacon.minor)))
        let beaconId = composeBeaconID(region: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor))
        let serverBeacon = ServerBeacon(id: beaconId,
                                        lat: 0,
                                        lng: 0,
                                        alt: 1,
                                        surfaceId: surface,
                                        beaconType: "IBEACON",
                                        beaconState: "ACTIVE")
        
        serverBeaconsService.putNonGeoBeacon(beacon: serverBeacon, position: position) { success, errorMessage in
            SwiftSpinner.hide()
            if success {
                self.installSoundEffect?.play()
                self.addBeaconInHistoric(actionType: .install, region: beacon.uuid.uuidString, major: beacon.major, minor: beacon.minor, position: position)
                completion(true, errorMessage)
            } else {
                self.errorSoundEffect?.play()
                completion(false, errorMessage)
            }
        }
    }
    
    public func retrieve(iBeacon beacon: CLBeacon, completion: @escaping (Bool, String?) -> Void) {
        guard let isGeoMap = SurfaceService.shared.isGeoSurface else {
            completion(false, "Cannot find surface data")
            return
        }
        
        if isGeoMap {
            retrieveBeaconManual(regionUUID: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor)) { success, errorMessage in
                 completion(success, errorMessage)
            }
        } else {
            retrieveNonGeoBeaconManual(regionUUID: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor)) { success, errorMessage in
                        completion(success, errorMessage)
                   }
        }
    }
    
    public func retrieveBeaconManual(regionUUID: String, major: Int, minor: Int, completion: @escaping (Bool, String?) -> Void) {
        SwiftSpinner.show("Retrieving iBeacon " + String(format: "%04d", minor))
        let beaconId = composeBeaconID(region: regionUUID, major: major, minor: minor)
        
        serverBeaconsService.getBeacon(withId: beaconId) { success, errorMessage, serverBeacon in
            SwiftSpinner.hide()
            if success {
                if var updatedServerBeacon = serverBeacon {
                    updatedServerBeacon.beaconState = "RETRIEVED"
                    self.serverBeaconsService.updateBeacon(beacon: updatedServerBeacon) { success, updateErrorMessage in
                        if success {
                            self.retrieveSoundEffect?.play()
                            self.addBeaconInHistoric(actionType: .retrieve, region: regionUUID, major: NSNumber(value: major), minor: NSNumber(value: minor))
                            completion(true, nil)
                        } else {
                            self.errorSoundEffect?.play()
                            completion(false, updateErrorMessage)
                        }
                    }
                } else {
                    self.errorSoundEffect?.play()
                    completion(false, errorMessage)
                }
            } else {
                self.errorSoundEffect?.play()
                completion(false, errorMessage)
            }
        }
    }
    
    public func retrieveNonGeoBeaconManual(regionUUID: String, major: Int, minor: Int, completion: @escaping (Bool, String?) -> Void) {
        SwiftSpinner.show("Retrieving iBeacon " + String(format: "%04d", minor))
        let beaconId = composeBeaconID(region: regionUUID, major: major, minor: minor)
        
        serverBeaconsService.getNonGeoBeacon(withId: beaconId) { success, errorMessage, serverBeaconData in
            SwiftSpinner.hide()
            if success {
                if var updatedServerBeaconData = serverBeaconData {
                    guard var propertiesJSON = updatedServerBeaconData["properties"] as? [String: Any],
                        let beaconID = propertiesJSON["id"] as? String else {
                        self.errorSoundEffect?.play()
                        completion(false, "Didn't receive the right data for this iBeacon")
                        return
                    }
                    propertiesJSON.updateValue("RETRIEVED", forKey: "beaconState")
                    updatedServerBeaconData.updateValue(propertiesJSON, forKey: "properties")
                    self.serverBeaconsService.updateNonGeoBeacon(withID: beaconID, beaconData: updatedServerBeaconData) { success, updateErrorMessage in
                        if success {
                            self.retrieveSoundEffect?.play()
                            self.addBeaconInHistoric(actionType: .retrieve, region: regionUUID, major: NSNumber(value: major), minor: NSNumber(value: minor))
                            completion(true, nil)
                        } else {
                            self.errorSoundEffect?.play()
                            completion(false, updateErrorMessage)
                        }
                    }
                } else {
                    self.errorSoundEffect?.play()
                    completion(false, errorMessage)
                }
            } else {
                self.errorSoundEffect?.play()
                completion(false, errorMessage)
            }
        }
    }
    
    public func deleteAndInstallBeacon(iBeacon beacon: CLBeacon, at location: CLLocationCoordinate2D, completion: @escaping (Bool, String?) -> Void) {
        guard let surface = SurfaceService.shared.surfaceId else {
            completion(false, "Cannot find the surface ID for installation")
            return
        }
        
        SwiftSpinner.show("Deleting + Installing iBeacon " + String(format: "%04d", Int(truncating: beacon.minor)))
        let beaconId = composeBeaconID(region: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor))
        let serverBeacon = ServerBeacon(id: beaconId,
                                        lat: location.latitude,
                                        lng: location.longitude,
                                        alt: 1,
                                        surfaceId: surface,
                                        beaconType: "IBEACON",
                                        beaconState: "ACTIVE")
        
        serverBeaconsService.deleteBeacon(withID: beaconId) { _ in
            self.serverBeaconsService.putBeacon(beacon: serverBeacon) { success, errorMessage in
                SwiftSpinner.hide()
                if success {
                    self.installSoundEffect?.play()
                    self.addBeaconInHistoric(actionType: .install, region: beacon.uuid.uuidString, major: beacon.major, minor: beacon.minor, coordinates: location)
                    completion(true, errorMessage)
                } else {
                    self.errorSoundEffect?.play()
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    public func deleteAndInstallBeacon(iBeacon beacon: CLBeacon, nonGeoPosition position: CGPoint, completion: @escaping (Bool, String?) -> Void) {
        guard let surface = SurfaceService.shared.surfaceId else {
            completion(false, "Cannot find the surface ID for installation")
            return
        }
        
        SwiftSpinner.show("Deleting + Installing iBeacon " + String(format: "%04d", Int(truncating: beacon.minor)))
        let beaconId = composeBeaconID(region: beacon.uuid.uuidString, major: Int(truncating: beacon.major), minor: Int(truncating: beacon.minor))
        let serverBeacon = ServerBeacon(id: beaconId,
                                        lat: 0,
                                        lng: 0,
                                        alt: 1,
                                        surfaceId: surface,
                                        beaconType: "IBEACON",
                                        beaconState: "ACTIVE")

        serverBeaconsService.deleteBeacon(withID: beaconId) { _ in
            self.serverBeaconsService.putNonGeoBeacon(beacon: serverBeacon, position: position) { success, errorMessage in
                SwiftSpinner.hide()
                if success {
                    self.installSoundEffect?.play()
                    self.addBeaconInHistoric(actionType: .install, region: beacon.uuid.uuidString, major: beacon.major, minor: beacon.minor, position: position)
                    completion(true, errorMessage)
                } else {
                    self.errorSoundEffect?.play()
                    completion(false, errorMessage)
                }
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
    
    private func addBeaconInHistoric(actionType: BeaconSessionType, region: String, major: NSNumber, minor: NSNumber, coordinates: CLLocationCoordinate2D? = nil, position: CGPoint? = nil) {
        let action = BeaconAction(type: actionType, region: region, major: Int(truncating: major), minor: Int(truncating: minor), coordinates: coordinates, position:  position)
        actionsHistoric.append(action)
    }
}
