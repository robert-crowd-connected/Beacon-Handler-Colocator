//
//  HandleBeaconsManualViewController.swift
//  Beacon Handler Colocator
//
//  Created by TCode on 26/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class RetrieveBeaconsManualViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sessionImageView: UIImageView!
    
    @IBOutlet weak var regionUUIDLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    
    @IBOutlet weak var minorTextField: UITextField!
    @IBOutlet weak var retrieveBeaconButton: UIButton!
    
    var regionUUIDString: String? = nil
    var majorInt: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        guard let uuid = UserDefaults.standard.value(forKey: kRegionUUIDStorageKey) as? String,
            let major = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int else {
                print("Retrieve beacons manually screen loaded without region UUID and major data. Redirected back to settings screen.")
                self.navigationController?.popViewController(animated: false)
                return
        }
        regionUUIDString = uuid
        majorInt = major
        configureViews()
    }
    
    private func configureViews() {
        titleLabel.textColor = UIColor.wizardPurple
        
        regionUUIDLabel.text = "Region UUID \(regionUUIDString!)"
        majorLabel.text = "Major \(majorInt!)"
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: retrieveBeaconButton.frame.size.width, height: retrieveBeaconButton.frame.size.height)
        gradient.colors = [UIColor.wizardPurple.cgColor, UIColor.wizardBlue.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        retrieveBeaconButton.layer.insertSublayer(gradient, at: 0)
    }
    
    @IBAction func actionRetrieveBeacon(_ sender: Any) {
        guard let minor = minorTextField.text, minor.count > 3, let minorInt = Int(minor) else {
            let alert = UIAlertController(title: "Invalid Minor",
                                                 message: "Minor value should have at least 3 characters", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            return
        }
        
        BeaconHandlingService.shared.retrieveBeaconManual(regionUUID: regionUUIDString!, major: majorInt!, minor: minorInt)
        
       //TODO Add it to a local list, no UserDefaults
       
       let successAlert = UIAlertController(title: "iBeacon successfully retrieved!",
                                            message: "\(majorLabel.text!)   Minor \(minor)", preferredStyle: .alert)
       self.present(successAlert, animated: false, completion: {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
               self.dismiss(animated: true, completion: nil)
           }
       })
    }
}
