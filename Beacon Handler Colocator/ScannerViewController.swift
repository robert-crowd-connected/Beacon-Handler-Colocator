//
//  ViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 20/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import UIKit
import CoreLocation

protocol ScannerViewControllerDelegate: class {
    func startScanner()
    func stopMonitoringBeacon(beacon: CLBeacon)
}

class ScannerViewController: UIViewController, ScannerViewControllerDelegate {

    var sessionType: BeaconSessionType!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sessionImageView: UIImageView!
    
    @IBOutlet weak var scannerStatusLabel: UILabel!
    @IBOutlet weak var scannerDataContainerView: UIView!
    @IBOutlet weak var regionUUIDLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var scannerStatusSwitch: UISwitch!
    
    @IBOutlet weak var noiseLevelLabel: UILabel!
    @IBOutlet weak var closestBeaconLabel: UILabel!
    
    @IBOutlet weak var displayHandledBeaconsButton: UIButton!
    @IBOutlet weak var resetBeaconsProximityButton: UIButton!
    
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
    
    var isBeaconTooFar = false
    var closestBeaconMinor: NSNumber? = nil {
        willSet(newValue) {
            configureStableClosesBeaconTimer()
        }
    }
    
    var detectedBeacons = [CLBeacon]()
    var excludedBeaconMinors = [NSNumber]()
    
    var closestBeacon: CLBeacon? = nil {
        didSet {
            if closestBeacon != nil {
                let distance = Double(round(1000 * closestBeacon!.accuracy) / 1000)
                closestBeaconLabel.text = "iBeacon searching... \n\n\nMinor \(closestBeacon!.minor)     \n\nAccuracy \(distance)     RSSI \(closestBeacon!.rssi)"
                
                if closestBeacon!.minor != closestBeaconMinor || isBeaconTooFar {
                    closestBeaconMinor = closestBeacon!.minor
                }
           } else {
                closestBeaconMinor = nil
                detectedBeacons.removeAll()
                closestBeaconLabel.text = "Closest Beacon Not Determined"
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
        
        configureViews()
        configureScanner()
        startScanner()
    }
    
    private func configureViews() {
        titleLabel.textColor = UIColor.wizardPurple
        scannerStatusLabel.textColor = UIColor.wizardMiddleColor
        resetBeaconsProximityButton.setTitleColor(UIColor.wizardPurple, for: .normal)
        displayHandledBeaconsButton.setTitleColor(UIColor.wizardPurple, for: .normal)
        
        scannerDataContainerView.layer.borderWidth = 1
        scannerDataContainerView.layer.borderColor = UIColor.lightGray.cgColor
        if sessionType == .install {
            sessionImageView.image = UIImage(named: "install")
        } else {
            sessionImageView.image = UIImage(named: "retrieve")
        }
    }
    
    private func configureScanner() {
        guard let regionUUID = UserDefaults.standard.value(forKey: kRegionUUIDStorageKey) as? String,
            let majorValue = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int else {
                print("No Scanning Settings found")
                return
        }
        regionConstraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: regionUUID)!,
                                                      major: CLBeaconMajorValue(majorValue))
    
        regionUUIDLabel.text = "Region UUID " + regionUUID
        majorLabel.text = "Major \(majorValue)"
    }
    
    internal func startScanner() {
        if regionConstraint == nil { return }
        
        closestBeacon = nil
        isBeaconTooFar = false
        detectedBeacons.removeAll()
        
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
    
    public func stopMonitoringBeacon(beacon: CLBeacon) {
        excludedBeaconMinors.append(beacon.minor)
    }
    
    private func restartScanner() {
        stopScanner()
        configureScanner()
        startScanner()
    }
    
    private func configureStableClosesBeaconTimer() {
        confirmStableClosestBeaconTimer?.invalidate()
        confirmStableClosestBeaconTimer = nil
        
        if closestBeacon == nil {
            isBeaconTooFar = false
            return
        }
        
        if closestBeacon!.rssi <= -25 || closestBeacon!.accuracy >= 0.03 {
            isBeaconTooFar = true
            return
        } else {
            isBeaconTooFar = false
        }
        
        // If beacon is right next to the phone, wait for 1.5 seconds. Otherwise wait 3 seconds
        let confirmationBeaconInterval = closestBeacon!.rssi >= -10 ? 1.5 : 3
        
        confirmStableClosestBeaconTimer = Timer.scheduledTimer(withTimeInterval: confirmationBeaconInterval, repeats: false, block: { _ in
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
        } else {
            stopScanner()
        }
    }
    
    private func installBeacon() {
        guard let beaconToBeInstalled = closestBeacon else {
            return
        }
        stopScanner()
        
        guard let beaconInstallationViewController = storyboard?.instantiateViewController(withIdentifier: "BeaconInstallationViewController") as? BeaconInstallationViewController else { return }
        beaconInstallationViewController.beacon = beaconToBeInstalled
        beaconInstallationViewController.delegate = self
        navigationController?.pushViewController(beaconInstallationViewController, animated: true)
    }
    
    private func retrieveBeacon() {
        guard let beaconToBeRetrieved = closestBeacon else {
            return
        }
        stopScanner()
        
        BeaconHandlingService.shared.retrieve(iBeacon: beaconToBeRetrieved) { success, errorMessage in
            if success {
                let successAlert = UIAlertController(title: "iBeacon successfully retrieved!",
                                                     message: "Major \(beaconToBeRetrieved.major)  Minor \(beaconToBeRetrieved.minor)", preferredStyle: .alert)
                self.present(successAlert, animated: false, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.stopMonitoringBeacon(beacon: beaconToBeRetrieved)
                        self.startScanner()
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            } else {
                let failureAlert = UIAlertController(title: "iBeacon retrieval failed!",
                                                     message: errorMessage ?? kDefaultRequestErrorMessage, preferredStyle: .alert)
                self.present(failureAlert, animated: false, completion: {
                     DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.startScanner()
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    @IBAction func actionResetProximity(_ sender: Any) {
        startScanner()
    }
    
    @IBAction func actionDisplayHistoric(_ sender: Any) {
        guard let historicViewController = storyboard?.instantiateViewController(withIdentifier: "HistoricViewController") as? HistoricViewController else { return }
        historicViewController.sessionType = sessionType
        self.present(historicViewController, animated: true, completion: nil)
    }
}

extension ScannerViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        guard !beacons.isEmpty else {
            return
        }

        for beacon in beacons {
            if (beacon.accuracy < 0 || beacon.proximity == .near || beacon.proximity == .far || beacon.proximity == .unknown) { continue }
            if excludedBeaconMinors.contains(beacon.minor) { continue }
            detectedBeacons.append(beacon)
        }
    }
}
