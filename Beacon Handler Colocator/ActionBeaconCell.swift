//
//  ActionBeaconCell.swift
//  Beacon Handler Colocator
//
//  Created by TCode on 26/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class ActionBeaconCell: UITableViewCell {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var UUIDLabel: UILabel!
    
    public func configure(action: BeaconAction) {
        
        descriptionLabel.text = action.description
        UUIDLabel.text = "UUID \(action.regionUUID)"
        
    }
}
