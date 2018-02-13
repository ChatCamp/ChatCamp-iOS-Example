//
//  OpenChannelsViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

class OpenChannelsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(ChatTableViewCell.nib(), forCellReuseIdentifier: ChatTableViewCell.string())
        }
    }
}

// MARK:- UITableViewDataSource
extension OpenChannelsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.string(), for: indexPath) as! ChatTableViewCell
        
        cell.nameLabel.text = "My chat"
        cell.messageLabel.text = "my messages are so unique that it extends to a long length so that it will truncate"
        
        return cell
    }
}

// MARK:- UITableViewDelegate
extension OpenChannelsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
