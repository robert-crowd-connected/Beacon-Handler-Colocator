//
//  OnboardingActionSelectionViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class OnboardingActionSelectionViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var installBeaconsButton: UIButton!
    @IBOutlet weak var retrieveBeaconsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        welcomeLabel.textColor = UIColor.wizardPurple
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: installBeaconsButton.frame.size.width, height: installBeaconsButton.frame.size.height)
        gradient.colors = [UIColor.wizardPurple.cgColor, UIColor.wizardBlue.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        installBeaconsButton.layer.insertSublayer(gradient, at: 0)
    }
    
    @IBAction func actionInstall(_ sender: Any) {
        guard let onboardingSettingsViewController = storyboard?.instantiateViewController(withIdentifier: "OnboardingSettingsViewController") as? OnboardingSettingsViewController else { return }
        onboardingSettingsViewController.sessionType = .install
        self.navigationController?.pushViewController(onboardingSettingsViewController, animated: true)
    }
    
    @IBAction func actionRetrieve(_ sender: Any) {
        guard let onboardingSettingsViewController = storyboard?.instantiateViewController(withIdentifier: "OnboardingSettingsViewController") as? OnboardingSettingsViewController else { return }
        onboardingSettingsViewController.sessionType = .retrieve
        self.navigationController?.pushViewController(onboardingSettingsViewController, animated: true)
    }
    
}
