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
//
        let pathRetrieve = Bundle.main.path(forResource: "retrieveBeacon.mp3", ofType:nil)!
        let urlRetrieve = URL(fileURLWithPath: pathRetrieve)

        do {
            retrieveSoundEffect = try AVAudioPlayer(contentsOf: urlRetrieve)
        } catch {
            // couldn't load file :(
        }
    }
    
    public func install(iBeacon beacon: CLBeacon, at location: CLLocationCoordinate2D) {
        installSoundEffect?.play()
        
        //TODO Call API with Beacon and Location data
    }
    
    public func retrieve(iBeacon beacon: CLBeacon) {
        retrieveSoundEffect?.play()
        
        //TODO Call API with beacon data
    }
    
    public func retrieveBeaconManual(minor: Int) {
        retrieveSoundEffect?.play()
        
        //TODO Get region uuid and major from UserDefaults
        // Call API with beacon data
    }
}
