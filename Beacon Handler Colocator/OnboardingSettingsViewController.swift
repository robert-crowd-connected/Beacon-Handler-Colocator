//
//  OnboardingSettingsViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class OnboardingSettingsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var sessionImageView: UIImageView!
    
    @IBOutlet weak var regionContainerView: UIView!
    @IBOutlet weak var majorContainerView: UIView!
    @IBOutlet weak var regionUUIDLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    
    @IBOutlet weak var regionUUIDTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var manualModeButton: UIButton!
    
    var sessionType: BeaconSessionType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if sessionType == .install {
            welcomeLabel.text = "Preparing beacon installation"
            sessionImageView.image = UIImage(named: "install")
        } else {
            welcomeLabel.text = "Preparing beacon retrieval"
            sessionImageView.image = UIImage(named: "retrieve")
        }
        welcomeLabel.textColor = UIColor.wizardPurple
        
        regionUUIDLabel.textColor = UIColor.wizardMiddleColor
        majorLabel.textColor = UIColor.wizardMiddleColor
        
        manualModeButton.setTitleColor(UIColor.wizardPurple, for: .normal)
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: continueButton.frame.size.width, height: continueButton.frame.size.height)
        gradient.colors = [UIColor.wizardPurple.cgColor, UIColor.wizardBlue.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        continueButton.layer.insertSublayer(gradient, at: 0)
        
        regionContainerView.layer.borderWidth = 1
        regionContainerView.layer.borderColor = UIColor.lightGray.cgColor
        
        majorContainerView.layer.borderWidth = 1
        majorContainerView.layer.borderColor = UIColor.lightGray.cgColor
        
        regionUUIDTextField.delegate = self
        majorTextField.delegate = self
        
        if let regionUUID = UserDefaults.standard.value(forKey: kRegionUUIDStorageKey) as? String,
            let majorValue = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int {
            regionUUIDTextField.text = regionUUID
            majorTextField.text = "\(majorValue)"
        } else {
            changeButtonsVisibility(to: false)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           self.view.endEditing(true)
           return false
       }
    
    @IBAction func actionChangedRegion(_ sender: UITextField) {
        if let newRegion = sender.text, newRegion.count > 20 {
            UserDefaults.standard.set(newRegion, forKey: kRegionUUIDStorageKey)
            checkSettings()
        }
    }
    
    @IBAction func actionChangedMajor(_ sender: UITextField) {
        if let newMajor = sender.text, newMajor.count < 6 {
            UserDefaults.standard.set(newMajor, forKey: kMajorValueStorageKey)
            checkSettings()
        }
    }
    
    private func checkSettings() {
        if regionUUIDTextField.text != nil && majorTextField.text != nil {
            changeButtonsVisibility(to: true)
        } else {
            changeButtonsVisibility(to: false)
        }
    }
    
    private func changeButtonsVisibility(to state: Bool) {
        continueButton.isHidden = !state
        manualModeButton.isHidden = !state
    }
    
    @IBAction func actionContinue(_ sender: Any) {
        guard let scannerViewController = storyboard?.instantiateViewController(withIdentifier: "ScannerViewController") as? ScannerViewController else { return }
        scannerViewController.sessionType = sessionType
        self.navigationController?.pushViewController(scannerViewController, animated: true)
    }
    
    @IBAction func actionManualMode(_ sender: Any) {
        guard let handleBeaconsManualViewController = storyboard?.instantiateViewController(withIdentifier: "HandleBeaconsManualViewController") as? HandleBeaconsManualViewController else { return }
        handleBeaconsManualViewController.sessionType = sessionType
        self.navigationController?.pushViewController(handleBeaconsManualViewController, animated: true)
    }
    
}
