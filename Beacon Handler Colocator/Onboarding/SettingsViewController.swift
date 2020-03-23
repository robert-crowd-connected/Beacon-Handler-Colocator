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
    
    @IBOutlet weak var zoomLavelLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = UIColor.wizardPurple
        let serverIndex = UserDefaults.standard.value(forKey: kServerUsedIndexStorageKey) as? Int ?? 2
        serverUsedSegmentedControl.selectedSegmentIndex = serverIndex
        
        let zoomLevel = UserDefaults.standard.value(forKey: kZoomLevelStorageKey) as? Int ?? 7
        zoomLavelLabel.text = "\(zoomLevel)"
    }
    
    @IBAction func actionChangedServerUsed(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: kServerUsedIndexStorageKey)
    }
    
    @IBAction func acttionMinusZoom(_ sender: Any) {
        var zoomLevel = UserDefaults.standard.value(forKey: kZoomLevelStorageKey) as? Int ?? 7
        if zoomLevel >= 1 {
            zoomLevel -= 1
            zoomLavelLabel.text = "\(zoomLevel)"
            UserDefaults.standard.set(zoomLevel, forKey: kZoomLevelStorageKey)
        }
    }
    
    @IBAction func actionPlusZoom(_ sender: Any) {
        var zoomLevel = UserDefaults.standard.value(forKey: kZoomLevelStorageKey) as? Int ?? 7
        if zoomLevel <= 20 {
            zoomLevel += 1
            zoomLavelLabel.text = "\(zoomLevel)"
            UserDefaults.standard.set(zoomLevel, forKey: kZoomLevelStorageKey)
        }
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
