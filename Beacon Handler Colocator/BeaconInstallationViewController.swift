//
//  BeaconInstallationViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class BeaconInstallationViewController: UIViewController {
    
    @IBOutlet weak var beaconDataLabel: UILabel!
    
    public var beacon: CLBeacon!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beaconDataLabel.text = "iBeacon Major \(beacon.major)  Minor \(beacon.minor) \nUUID \(beacon.uuid)"
    }
    
    @IBAction func actionInstall(_ sender: Any) {
        let successAlert = UIAlertController(title: "iBeacon successfully isntalled!",
                                      message: nil, preferredStyle: .alert)
        self.present(successAlert, animated: false, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func actionCancelInstallation(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
