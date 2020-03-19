//
//  SettingsViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 17/03/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var serverUsedLabel: UILabel!
    @IBOutlet weak var serverUsedSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var mapTypeLabel: UILabel!
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = UIColor.wizardPurple
        let serverIndex = UserDefaults.standard.value(forKey: kServerUsedIndexStorageKey) as? Int ?? 2
        serverUsedSegmentedControl.selectedSegmentIndex = serverIndex
        
        let mapTypeIndex = UserDefaults.standard.value(forKey: kGeoPositionMapStorageKey) as? Int ?? 1
        mapTypeSegmentedControl.selectedSegmentIndex = mapTypeIndex
    }
    
    @IBAction func actionChangedServerUsed(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: kServerUsedIndexStorageKey)
    }
    
    @IBAction func actionChangedMapType(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: kGeoPositionMapStorageKey)
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
