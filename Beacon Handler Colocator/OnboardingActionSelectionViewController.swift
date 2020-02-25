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
