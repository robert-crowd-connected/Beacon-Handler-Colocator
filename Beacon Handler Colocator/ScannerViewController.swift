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
    
    var isBeaconTooFar = false
    var detectedBeacons = [CLBeacon]()
    var excludedBeaconMinors = [NSNumber]()
    
    var closestBeacon: CLBeacon? = nil {
        didSet {
            if closestBeacon != nil {
                let beaconAccuracy = Double(round(1000 * closestBeacon!.accuracy) / 1000)
                closestBeaconLabel.text = "iBeacon searching... \n\n\nMinor \(closestBeacon!.minor)     \n\nAccuracy \(beaconAccuracy)     RSSI \(closestBeacon!.rssi)"
                
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
    
    var closestBeaconMinor: NSNumber? = nil {
        willSet(newValue) {
            configureStableClosesBeaconTimer()
        }
    }
    
    var noiseLevel: NoiseLevel = .none {
        didSet {
            noiseLevelLabel.text = "Noise Level \(noiseLevel.rawValue)"
            if confirmStableClosestBeaconTimer != nil && noiseLevel == .medium || noiseLevel == .high || noiseLevel == .veryHigh {
                configureStableClosesBeaconTimer()
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
            let majorValue = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int else { return }
        regionConstraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: regionUUID)!,
                                                      major: CLBeaconMajorValue(majorValue))
    
        regionUUIDLabel.text = "Region UUID " + regionUUID
        majorLabel.text = "Major \(majorValue)"
    }
    
    internal func startScanner() {
        closestBeacon = nil
        isBeaconTooFar = false
        detectedBeacons.removeAll()
        
        if regionConstraint == nil { return }
        locationManager.startRangingBeacons(satisfying: regionConstraint!)
        
        closestBeaconTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            self.updateClosestBeacon()
        })
        refreshDetectedBeaconsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
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
        
        if closestBeacon == nil { return }
        
        if closestBeacon!.rssi <= -23 || closestBeacon!.accuracy >= 0.03 {
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
        (closestBeacon, noiseLevel) = BeaconsPositionCalculator.calculateClosestBeaconAndNoiseLevel(detectedBeacons: detectedBeacons)
    }
    
    @objc func refreshDetectedBeacons() {
        detectedBeacons = detectedBeacons.filter({ (beacon) -> Bool in
            beacon.timestamp.timeIntervalSince1970 + 4.0 > Date().timeIntervalSince1970
        })
    }
    
    private func installBeacon() {
        guard let beaconToBeInstalled = closestBeacon else { return }
        stopScanner()
        
        let geoMapInstallation = UserDefaults.standard.value(forKey: kGeoPositionMapStorageKey) as? Bool ?? false
        
        if geoMapInstallation {
            guard let beaconInstallationViewController = storyboard?.instantiateViewController(withIdentifier: "BeaconInstallationViewController")
                as? BeaconInstallationViewController else { return }
            beaconInstallationViewController.beacon = beaconToBeInstalled
            beaconInstallationViewController.delegate = self
            
            navigationController?.pushViewController(beaconInstallationViewController, animated: true)
        } else {
            guard let nonGeoBeaconViewController = storyboard?.instantiateViewController(withIdentifier: "NonGeoBeaconInstallationViewController")
                as? NonGeoBeaconInstallationViewController else { return }
            nonGeoBeaconViewController.beacon = beaconToBeInstalled
            nonGeoBeaconViewController.delegate = self
            
            navigationController?.pushViewController(nonGeoBeaconViewController, animated: true)
        }
    }
       
    private func retrieveBeacon() {
        guard let beaconToBeRetrieved = closestBeacon else { return }
        stopScanner()
        
        BeaconHandlingService.shared.retrieve(iBeacon: beaconToBeRetrieved) { success, errorMessage in
            if success {
                let successAlert = UIAlertController(title: "iBeacon successfully retrieved!",
                                                     message: "Major \(beaconToBeRetrieved.major)  Minor \(beaconToBeRetrieved.minor)",
                                                     preferredStyle: .alert)
                
                self.present(successAlert, animated: false, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.stopMonitoringBeacon(beacon: beaconToBeRetrieved)
                        self.startScanner()
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            } else {
                let failureAlert = UIAlertController(title: "iBeacon retrieval failed!",
                                                     message: errorMessage ?? kDefaultRequestErrorMessage,
                                                     preferredStyle: .alert)
                
                self.present(failureAlert, animated: false, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.startScanner()
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    @IBAction func actionBack(_ sender: Any) {
        stopScanner()
        closestBeacon = nil
        isBeaconTooFar = false
        detectedBeacons.removeAll()
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionMonitoringStatusChanged(_ sender: UISwitch) {
        sender.isOn ? startScanner() : stopScanner()
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
        guard !beacons.isEmpty else { return }

        for beacon in beacons {
            if (beacon.accuracy < 0 || beacon.proximity == .near || beacon.proximity == .far || beacon.proximity == .unknown) { continue }
            if excludedBeaconMinors.contains(beacon.minor) { continue }
            detectedBeacons.append(beacon)
        }
    }
}
