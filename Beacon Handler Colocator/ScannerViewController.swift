//
//  ViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 20/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftSpinner

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
    
    // A beacon should be at most 50cm apart from the phone
    // to be validated as closest beacon.
    // This behaviour prevent validating the closest beacon
    // by mistake, avoiding issues like restrieving a wrong beacon
    var isBeaconTooFar = false
    
    // The beacons installed in the current session
    // will be saved locally and ignored when scanning
    // for new beacons to install, hence reducing unwanted noise
    var detectedBeacons = [CLBeacon]()
    var excludedBeaconMinors = [NSNumber]()
    
    var closestBeacon: CLBeacon? = nil {
        didSet {
            if closestBeacon != nil {
                let beaconAccuracy = Double(round(1000 * closestBeacon!.accuracy) / 1000)
                
                var closestBeaconTitle = "Identifying closest iBeacon ... \n\n\nMinor \(closestBeacon!.minor)"
                if closestBeacon!.rssi < -23 || beaconAccuracy > 0.03 {
                    closestBeaconTitle.append("\n\n\nTOO FAR")
                }
                    
                closestBeaconLabel.text = closestBeaconTitle
                
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
    
    // Noise level is determined by the number of beacons nearby (< 1.5m)
    // and the distance between the closest beacon and the rest of them.
    // As long as there is medium noise (or worse), for safety reasons,
    // the app won't validate the closest beacon.
    var noiseLevel: NoiseLevel = .none {
        didSet {
            noiseLevelLabel.text = "Noise Level: \(noiseLevel.rawValue)"
            if confirmStableClosestBeaconTimer != nil && noiseLevel == .medium || noiseLevel == .high || noiseLevel == .veryHigh {
                configureStableClosesBeaconTimer()
            }
        }
    }
    
    // At every 0.5 seconds, the closest beacon is updated
    // by analyzing the available data and the criterias.
    // A beacon should remain the closest one for 1.5 or 3 seconds straight
    // to be validated.
    // If it is closer than ~30cm, 1.5 seconds are required,
    // otherwise 3 seconds are required
    var closestBeaconTimer: Timer?
    var refreshDetectedBeaconsTimer: Timer?
    var confirmStableClosestBeaconTimer: Timer?
    
    var surfaceDataRequestFinished = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = -1
        
        configureViews()
        configureScanner()
        startScanner()
        
        SwiftSpinner.show("Preparing Beacon Handling Setup")
        
        // Get surface data (tile or map image) before detecting the closest beacon
        // for a frictionless experience
        // Also, if that fails, the user should be warned and the process should be stopped
        SurfaceService.shared.getSurfaceData { success, message in
            SwiftSpinner.hide()
            self.surfaceDataRequestFinished = true
            
            if !success {
                let alert = UIAlertController(title: "Download failed!",
                                              message: message ?? "Failed to download surface data", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                self.present(alert, animated: false, completion: { })
            }
        }
    }
    
    private func configureViews() {
        titleLabel.textColor = UIColor.wizardPurple
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
    
        regionUUIDLabel.text = "Region " + regionUUID
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
    }
    
    private func stopScanner() {
        if regionConstraint == nil { return }
        locationManager.stopRangingBeacons(satisfying: regionConstraint!)
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
        
        // Wait for surface data to be downloaded if it's not available yet
        // In most cases 2 seconds should be enough
        if surfaceDataRequestFinished == false {
            sleep(2)
        }
        
        if SurfaceService.shared.isGeoSurface == true {
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
        
        // Wait for surface data to be downloaded if it's not available yet
        // In most cases 2 seconds should be enough
        if surfaceDataRequestFinished == false {
            sleep(2)
        }
        
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
    
    @IBAction func actionResetProximity(_ sender: Any) {
        startScanner()
    }
    
    @IBAction func actionDisplayHistoric(_ sender: Any) {
        guard let historicViewController = storyboard?.instantiateViewController(withIdentifier: "HistoricViewController")
            as? HistoricViewController else { return }
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
