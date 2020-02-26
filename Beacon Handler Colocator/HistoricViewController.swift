//
//  HistoricViewController.swift
//  Beacon Handler Colocator
//
//  Created by TCode on 26/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class HistoricViewController: UIViewController {
    
    var sessionType: BeaconSessionType!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sessionImageView: UIImageView!
    @IBOutlet weak var actionsTableView: UITableView!
    
    var actions = [BeaconAction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.textColor = UIColor.wizardPurple
        if sessionType == .install {
            sessionImageView.image = UIImage(named: "install")
        } else {
            sessionImageView.image = UIImage(named: "retrieve")
        }
        
        loadHistoricData()
    }
    
    private func loadHistoricData() {
        actions = BeaconHandlingService.shared.getActionsHistoric()
        actionsTableView.reloadData()
    }
}

extension HistoricViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = actions[indexPath.row].description
        cell.textLabel?.textColor = UIColor.darkGray
        cell.textLabel?.font = UIFont(name: "HelveticaNueue", size: 15)
        return cell
    }
}
