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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionsTableView: UITableView!
    
    var actions = [BeaconAction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.textColor = UIColor.wizardPurple
        
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionBeaconCell") as? ActionBeaconCell else {
            return UITableViewCell()
        }
        cell.configure(action: actions[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}
