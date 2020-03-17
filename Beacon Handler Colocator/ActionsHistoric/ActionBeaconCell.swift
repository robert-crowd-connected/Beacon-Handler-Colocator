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
    @IBOutlet weak var coordinatesLabel: UILabel!
    
    public func configure(action: BeaconAction) {
        
        descriptionLabel.text = action.description
        UUIDLabel.text = "UUID \(action.regionUUID)"
        if let coord = action.coordinates {
            coordinatesLabel.text = "Lat \(coord.latitude)   Lon \(coord.longitude)"
        } else if let position = action.position {
            coordinatesLabel.text = "X \(position.x)   Y \(position.y)"
        } else {
            coordinatesLabel.text = "Beacon Retrieved"
        }
    }
}
