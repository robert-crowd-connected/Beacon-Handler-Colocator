//
//  OnboardingSettingsViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class OnboardingSettingsViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var sessionImageView: UIImageView!
    
    @IBOutlet weak var appKeyContainerView: UIView!
    @IBOutlet weak var regionContainerView: UIView!
    @IBOutlet weak var majorContainerView: UIView!
    
    @IBOutlet weak var appKeyLabel: UILabel!
    @IBOutlet weak var regionUUIDLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    
    @IBOutlet weak var appKeyTextField: UITextField!
    @IBOutlet weak var regionUUIDTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var manualModeButton: UIButton!
    
    var sessionType: BeaconSessionType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    private func configureViews() {
        if sessionType == .install {
            welcomeLabel.text = "Preparing beacon installation"
            sessionImageView.image = UIImage(named: "install")
            manualModeButton.isHidden = true
        } else {
            welcomeLabel.text = "Preparing beacon retrieval"
            sessionImageView.image = UIImage(named: "retrieve")
            manualModeButton.isHidden = false
        }
        
        welcomeLabel.textColor = UIColor.wizardPurple
        appKeyLabel.textColor = UIColor.wizardMiddleColor
        regionUUIDLabel.textColor = UIColor.wizardMiddleColor
        majorLabel.textColor = UIColor.wizardMiddleColor
        manualModeButton.setTitleColor(UIColor.wizardPurple, for: .normal)
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: continueButton.frame.size.width, height: continueButton.frame.size.height)
        gradient.colors = [UIColor.wizardPurple.cgColor, UIColor.wizardBlue.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        continueButton.layer.insertSublayer(gradient, at: 0)
        
        appKeyContainerView.layer.borderWidth = 1
        appKeyContainerView.layer.borderColor = UIColor.lightGray.cgColor
        regionContainerView.layer.borderWidth = 1
        regionContainerView.layer.borderColor = UIColor.lightGray.cgColor
        majorContainerView.layer.borderWidth = 1
        majorContainerView.layer.borderColor = UIColor.lightGray.cgColor
        
        if let key = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String,
            let regionUUID = UserDefaults.standard.value(forKey: kRegionUUIDStorageKey) as? String,
            let majorValue = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int {
            appKeyTextField.text = key
            regionUUIDTextField.text = regionUUID
            majorTextField.text = "\(majorValue)"
        } else {
            changeButtonsVisibility(to: false)
        }
    }
    
    @IBAction func actionSettings(_ sender: Any) {
        guard let settingsViewController = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")
            as? SettingsViewController else { return }
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    @IBAction func actionChangeAppKey(_ sender: UITextField) {
        if let newKey = sender.text, newKey.count == 8 {
            UserDefaults.standard.set(newKey, forKey: kApplicationKeyStorageKey)
            checkSettings()
            let successAlert = UIAlertController(title: "Application Key successfully updated!",
                                                 message: nil, preferredStyle: .alert)
            self.present(successAlert, animated: false, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
    
    @IBAction func actionChangedRegion(_ sender: UITextField) {
        if let newRegion = sender.text, newRegion.count > 20 {
            UserDefaults.standard.set(newRegion, forKey: kRegionUUIDStorageKey)
            checkSettings()
        }
    }
    
    @IBAction func actionChangedMajor(_ sender: UITextField) {
        if let newMajor = sender.text, let newMajorInt = Int(newMajor) {
            UserDefaults.standard.set(newMajorInt, forKey: kMajorValueStorageKey)
            checkSettings()
        } else {
            UserDefaults.standard.removeObject(forKey: kMajorValueStorageKey)
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
    }
    
    private func checkSettingsConfiguration() -> Bool {
        if let _ = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String,
            let _ = UserDefaults.standard.value(forKey: kRegionUUIDStorageKey) as? String,
            let _ = UserDefaults.standard.value(forKey: kMajorValueStorageKey) as? Int {
            return true
        } else {
            return false
        }
    }
    
    @IBAction func actionContinue(_ sender: Any) {
        if !checkSettingsConfiguration() {
            let alert = UIAlertController(title: "Configuration data missing",
                                                 message: "Make sure an App Key, a region UUID and a Major are set up before continuing", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            return
        }
        
        guard let scannerViewController = storyboard?.instantiateViewController(withIdentifier: "ScannerViewController")
            as? ScannerViewController else { return }
        scannerViewController.sessionType = sessionType
        self.navigationController?.pushViewController(scannerViewController, animated: true)
    }
    
    @IBAction func actionManualMode(_ sender: Any) {
        guard let handleBeaconsManualViewController = storyboard?.instantiateViewController(withIdentifier: "HandleBeaconsManualViewController")
            as? RetrieveBeaconsManualViewController else { return }
        self.navigationController?.pushViewController(handleBeaconsManualViewController, animated: true)
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
