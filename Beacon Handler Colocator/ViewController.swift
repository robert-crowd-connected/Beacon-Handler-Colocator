//
//  ViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 20/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var beaconsTypeSegmentControl: UISegmentedControl!
    @IBOutlet weak var majorValueTextField: UITextField!
    @IBOutlet weak var scannerStatusSwitch: UISwitch!
    
    @IBOutlet weak var closestBeaconLabel: UILabel!
    
    @IBOutlet weak var installBeaconButton: UIButton!
    @IBOutlet weak var retrieveBeaconButton: UIButton!
    
    // For the best proximity and accuracy, place the iPhone with the lock screen button next to the beacon
    // The best results are when the beacon in NOT on the back of the phone or over the screen
    
    lazy fileprivate var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    var regionConstraint: CLBeaconIdentityConstraint?
    var beaconsCategory: BeaconCategory = .battery
       
    var detectedBeacons = [CLBeacon]()
    var closestBeacon: CLBeacon? = nil {
        didSet {
            if closestBeacon != nil {
               let distance = Double(round(1000*closestBeacon!.accuracy)/1000)
               closestBeaconLabel.text = "Closest Beacon\n\nMinor \(closestBeacon!.minor)     Distance \(distance)m     RSSI \(closestBeacon!.rssi)"
                setBeaconActionButtonVisibility(to: true)
           } else {
               closestBeaconLabel.text = "Closest Beacon Not Determined"
                setBeaconActionButtonVisibility(to: false)
           }
        }
    }
    
    var closestBeaconTimer: Timer?
    var refreshDetectedBeaconsTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        configureScanner()
        configureViews()
        startScanner()
    }
    
    private func configureScanner() {
        beaconsCategory = BeaconCategory(rawValue: UserDefaults.standard.value(forKey: kBeaconCattegoryStorageKey) as? Int ?? 1)!
        let majorValue = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int ?? 0
        regionConstraint = CLBeaconIdentityConstraint(uuid: beaconsCategory.regionUUID,
                                                      major: CLBeaconMajorValue(majorValue))
        closestBeacon = nil
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
    
    private func configureViews() {
        majorValueTextField.delegate = self
        setBeaconActionButtonVisibility(to: false)
        beaconsTypeSegmentControl.selectedSegmentIndex = beaconsCategory.rawValue
        majorValueTextField.text = "\(UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int ?? 0)"
    }
    
    private func setBeaconActionButtonVisibility(to status: Bool) {
        installBeaconButton.isHidden = !status
        retrieveBeaconButton.isHidden = !status
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
            beacon.timestamp.timeIntervalSince1970 + 3.5 > now // removed beacons appearances from more than 3 seconds ago
        })
    }
    
    @IBAction func actionChangeBeaconsType(_ sender: UISegmentedControl) {
        let rawBeaconsType = sender.selectedSegmentIndex
        UserDefaults.standard.set(rawBeaconsType, forKey: kBeaconCattegoryStorageKey)
        restartScanner()
    }
    
    @IBAction func actionChangeMajorValue(_ sender: UITextField) {
        guard let major = sender.text else { return }
        guard let majorInt = Int(major) else { return }
        UserDefaults.standard.set(majorInt, forKey: kMajorValueStorageKey)
        restartScanner()
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
        if closestBeacon == nil { return }
        guard let beaconInstallationViewController = storyboard?.instantiateViewController(withIdentifier: "BeaconInstallationViewController") as? BeaconInstallationViewController else { return }
        beaconInstallationViewController.beacon = closestBeacon!
        navigationController?.pushViewController(beaconInstallationViewController, animated: true)
    }
    
    @IBAction func actionRetrieveBeacon(_ sender: Any) {
        if closestBeacon == nil { return }
        let alert = UIAlertController(title: "Retrieve the Beacon?",
                                      message: "Are you sure you want to retrieve iBeacon (Major \(closestBeacon!.major),  Minor \(closestBeacon!.minor))?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            //TODO Call API with beacon data and retrieve it
            
            let successAlert = UIAlertController(title: "iBeacon successfully retrieved!",
                                          message: nil, preferredStyle: .alert)
            self.present(successAlert, animated: false, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
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
            
//            print("""
//                
//            Minor: \(beacon.minor)
//            RSSI: \(beacon.rssi)
//            Proximity: \(beacon.proximity.rawValue)
//            Accuracy: \(beacon.accuracy)
//            """)
        }
    }
}
