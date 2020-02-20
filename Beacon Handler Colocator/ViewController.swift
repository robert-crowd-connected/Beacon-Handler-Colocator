//
//  ViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 20/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var closestBeaconLabel: UILabel!
    
    private var beaconRegionUUID = UUID(uuidString: "1a9a515e-a845-467e-a313-3a8735f47514")!
    private var beaconsMajor = 0
    
    lazy fileprivate var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    var regionConstraint: CLBeaconIdentityConstraint {
        let region = CLBeaconIdentityConstraint(uuid: beaconRegionUUID, major: CLBeaconMajorValue(beaconsMajor))
        return region
    }
    
    var detectedBeacons = [CLBeacon]()
    var closestBeacon: CLBeacon? = nil {
        didSet {
            if closestBeacon != nil {
               let distance = Double(round(1000*closestBeacon!.accuracy)/1000)
               closestBeaconLabel.text = "Closest Beacon\n\nMinor \(closestBeacon!.minor)     Distance \(distance)m     RSSI \(closestBeacon!.rssi)"
           } else {
               closestBeaconLabel.text = "Closest Beacon Not Determined"
           }
        }
    }
    var closestBeaconTimer: Timer?
    var refreshDetectedBeaconsTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startRangingBeacons(satisfying: regionConstraint)
        
        closestBeaconTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            self.updateClosestBeacon()
        })
        
        refreshDetectedBeaconsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.refreshDetectedBeacons()
        })
    }
    
    @objc func updateClosestBeacon() {
        var max = -1000
        for beacon in detectedBeacons {
            if beacon.rssi > max {
                closestBeacon = beacon
                max = closestBeacon!.rssi
            } else if beacon.rssi == max && closestBeacon != nil {
                if closestBeacon!.accuracy > beacon.accuracy {
                    closestBeacon = beacon
                }
            }
        }
    }
    
    @objc func refreshDetectedBeacons() {
        let now = Date().timeIntervalSince1970
        detectedBeacons = detectedBeacons.filter({ (beacon) -> Bool in
            beacon.timestamp.timeIntervalSince1970 + 4 > now // removed beacons appearances from more than 4 seconds ago
        })
    }
    
    @IBAction func actionMonitoringStatusChanged(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startRangingBeacons(satisfying: regionConstraint)
            detectedBeacons.removeAll()
            closestBeacon = nil
        } else {
            locationManager.stopRangingBeacons(satisfying: regionConstraint)
        }
    }
    
    @IBAction func actionPrintBeacons(_ sender: Any) {
        print(detectedBeacons)
    }
    
    @IBAction func actionResetProximity(_ sender: Any) {
        closestBeacon = nil
        detectedBeacons.removeAll()
        closestBeaconLabel.text = "Closest Beacon Not Determined"
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        guard !beacons.isEmpty else {
            return
        }
        
        for beacon in beacons {
            if (beacon.accuracy < 0 || beacon.proximity == .near || beacon.proximity == .far || beacon.proximity == .unknown) { continue }
            
            detectedBeacons.append(beacon)
            
            print("""
                
            Minor: \(beacon.minor)
            RSSI: \(beacon.rssi)
            Proximity: \(beacon.proximity.rawValue)
            Accuracy: \(beacon.accuracy)
            """)
        }
    }
}



