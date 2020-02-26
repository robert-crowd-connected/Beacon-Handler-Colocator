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
    
    var actions = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        titleLabel.textColor = UIColor.wizardPurple
        
        //load data
    }
    
}

extension HistoricViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
