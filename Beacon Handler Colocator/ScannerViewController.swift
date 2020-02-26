//
//  ViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 20/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import UIKit
import CoreLocation

class ScannerViewController: UIViewController {

    var sessionType: BeaconSessionType!
    
    @IBOutlet weak var scannerDataContainerView: UIView!
    @IBOutlet weak var regionUUIDLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var scannerStatusSwitch: UISwitch!
    
    @IBOutlet weak var noiseLevelLabel: UILabel!
    @IBOutlet weak var closestBeaconLabel: UILabel!
    @IBOutlet weak var installBeaconButton: UIButton!
    
    // For the best proximity and accuracy, place the iPhone with the lock screen button next to the beacon
    // The best results are when the beacon in NOT on the back of the phone or over the screen
    
    lazy fileprivate var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    var regionConstraint: CLBeaconIdentityConstraint?
       
    var noiseLevel: NoiseLevel = .none {
        didSet {
            noiseLevelLabel.text = "Noise Level \(noiseLevel.rawValue)"
            if confirmStableClosestBeaconTimer != nil && noiseLevel == .medium || noiseLevel == .high || noiseLevel == .veryHigh {
                configureStableClosesBeaconTimer()
            }
        }
    }
    
    var closestBeaconMinor: NSNumber? = nil {
        willSet(newValue) {
            if newValue != nil && newValue != closestBeaconMinor {
                configureStableClosesBeaconTimer()
            }
        }
    }
    
    var detectedBeacons = [CLBeacon]()
    var closestBeacon: CLBeacon? = nil {
        didSet {
            if closestBeacon != nil {
                let distance = Double(round(1000 * closestBeacon!.accuracy) / 1000)
                closestBeaconLabel.text = "Closest Beacon\n\nMinor \(closestBeacon!.minor)     Accuracy \(distance)     RSSI \(closestBeacon!.rssi)"
                
                if closestBeacon!.minor != closestBeaconMinor {
                    closestBeaconMinor = closestBeacon!.minor
                }
           } else {
                closestBeaconLabel.text = "Closest Beacon Not Determined"
                installBeaconButton.isHidden = true
                closestBeaconMinor = nil
           }
        }
    }
    
    var closestBeaconTimer: Timer?
    var refreshDetectedBeaconsTimer: Timer?
    var confirmStableClosestBeaconTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = -1
        
        scannerDataContainerView.layer.borderWidth = 1
        scannerDataContainerView.layer.borderColor = UIColor.lightGray.cgColor
        
        configureScanner()
        startScanner()
    }
    
    private func configureScanner() {
        guard let regionUUID = UserDefaults.standard.value(forKey: kRegionUUIDStorageKey) as? String,
            let majorValue = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int else {
                print("No Scanning Settings found")
                return
        }
        regionConstraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: regionUUID)!,
                                                      major: CLBeaconMajorValue(majorValue))
        closestBeacon = nil
        detectedBeacons.removeAll()
        
        regionUUIDLabel.text = "Region UUID " + regionUUID
        majorLabel.text = "Major \(majorValue)"
    }
    
    private func startScanner() {
        if regionConstraint == nil { return }
        locationManager.startRangingBeacons(satisfying: regionConstraint!)
        
        closestBeaconTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            self.updateClosestBeacon()
        })
        
        refreshDetectedBeaconsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.refreshDetectedBeacons()
        })
        
        scannerStatusSwitch.isOn = true
    }
    
    private func stopScanner() {
        if regionConstraint == nil { return }
        locationManager.stopRangingBeacons(satisfying: regionConstraint!)
        
        scannerStatusSwitch.isOn = false
    }
    
    private func restartScanner() {
        stopScanner()
        configureScanner()
        startScanner()
    }
    
    private func configureStableClosesBeaconTimer() {
        confirmStableClosestBeaconTimer?.invalidate()
        confirmStableClosestBeaconTimer = nil
        
        if closestBeacon!.rssi <= -30 || closestBeacon!.accuracy > 0.02 { return }
        
        confirmStableClosestBeaconTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
            if self.closestBeacon == nil { return }
            if self.sessionType == .retrieve {
                self.retrieveBeacon()
            } else {
                self.installBeacon()
            }
        })
    }
    
    @objc func updateClosestBeacon() {
        var max = -1000
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
        
        closestBeacon = intermediateClosestBeacon
        
        calculcateNoiseLevel(monitoredBeacons: allDifferentBeacons.count,          // up to 3 meters
                             closeBeacons: otherCloseBeacons.count,                // up to 1 meter
                             veryClosebeacons: otherVeryCloseBeacons.count)        // up to 0.5 meters
    }
    
    private func calculcateNoiseLevel(monitoredBeacons: Int, closeBeacons: Int, veryClosebeacons: Int) {
        if closeBeacons == 0 && veryClosebeacons == 0 {
            noiseLevel = .none
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
        }
    }
    
    @objc func refreshDetectedBeacons() {
        let now = Date().timeIntervalSince1970
        detectedBeacons = detectedBeacons.filter({ (beacon) -> Bool in
            beacon.timestamp.timeIntervalSince1970 + 4.0 > now // removed beacons appearances from more than 4 seconds ago
        })
    }
    
    @IBAction func actionMonitoringStatusChanged(_ sender: UISwitch) {
        if sender.isOn {
            startScanner()
            detectedBeacons.removeAll()
            closestBeacon = nil
        } else {
            stopScanner()
        }
    }
    
    @IBAction func actionInstallBeacon(_ sender: Any) {
        installBeacon()
    }
    
    private func installBeacon() {
        if closestBeacon == nil { return }
        guard let beaconInstallationViewController = storyboard?.instantiateViewController(withIdentifier: "BeaconInstallationViewController") as? BeaconInstallationViewController else { return }
        beaconInstallationViewController.beacon = closestBeacon!
        navigationController?.pushViewController(beaconInstallationViewController, animated: true)
    }
    
    private func retrieveBeacon() {
        // Stop scanning for making sure that the closestbeacon value is not changed meanwhile
        stopScanner()
        
        if closestBeacon == nil {
            startScanner()
            return
        }
        
        BeaconHandlingService.shared.retrieve(iBeacon: self.closestBeacon!)
        
        //TODO Make sound
        //TODO stop scanning for this beacon
        //TODO Add it to a local list, no UserDefaults
        
        let successAlert = UIAlertController(title: "iBeacon successfully retrieved!",
                                             message: nil, preferredStyle: .alert)
        self.present(successAlert, animated: false, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.dismiss(animated: true, completion: nil)
                //Restart scanning since the closestBeacon value can be changed now
                self.startScanner()
            }
        })
        
//        let alert = UIAlertController(title: "Retrieve the Beacon?",
//                                      message: "Are you sure you want to retrieve iBeacon (Major \(closestBeacon!.major),  Minor \(closestBeacon!.minor))?", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
//            BeaconHandlingService.shared.retrieve(iBeacon: self.closestBeacon!)
//
//            let successAlert = UIAlertController(title: "iBeacon successfully retrieved!",
//                                          message: nil, preferredStyle: .alert)
//            self.present(successAlert, animated: false, completion: {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    self.dismiss(animated: true, completion: nil)
//                    //Restart scanning since the closestBeacon value can be changed now
//                    self.startScanner()
//                }
//            })
//        }))
//        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
//            self.startScanner()
//        }))
//        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func actionResetProximity(_ sender: Any) {
        closestBeacon = nil
        detectedBeacons.removeAll()
    }
}

extension ScannerViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        guard !beacons.isEmpty else {
            return
        }
        
        for beacon in beacons {
            if (beacon.accuracy < 0 || beacon.proximity == .near || beacon.proximity == .far || beacon.proximity == .unknown) { continue }
            detectedBeacons.append(beacon)
            
//            print("Beacon RSSI \(beacon.rssi)   Accuracy \(beacon.accuracy)   Minor \(beacon.minor)")
        }
    }
}
