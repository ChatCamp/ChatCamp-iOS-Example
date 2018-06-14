//
//  ParticipantViewModel.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 14/06/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//


import Foundation
import UIKit
import ChatCamp

class ParticipantViewModelItem {
    private var user: CCPUser
    
    var isSelected = false
    
    var displayName: String {
        return user.getDisplayName() ?? ""
    }
    
    var avatarURL: String? {
        return user.getAvatarUrl()
    }
    
    var userId: String {
        return user.getId()
    }
    
    init(user: CCPUser) {
        self.user = user
    }
}

class ParticipantViewModel: NSObject {
    var users = [ParticipantViewModelItem]()
    var loadMoreUsers: (() -> ())?
    
    var didToggleSelection: ((_ hasSelection: Bool) -> ())? {
        didSet {
            didToggleSelection?(!selectedItems.isEmpty)
        }
    }
    
    var selectedItems: [ParticipantViewModelItem] {
        return users.filter { return $0.isSelected }
    }
    
    override init() {
        super.init()
    }
}

extension ParticipantViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.identifier, for: indexPath) as? ChatTableViewCell {
            cell.user = users[indexPath.row]
            
            cell.nameLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
            cell.messageLabel.text = ""
            cell.unreadCountLabel.isHidden = true
            cell.accessoryLabel.text = ""
            // select/deselect the cell
            if users[indexPath.row].isSelected {
                if !cell.isSelected {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            } else {
                if cell.isSelected {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
            
            return cell
        }
        return UITableViewCell()
    }
}

extension ParticipantViewModel: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // update ViewModel item
        users[indexPath.row].isSelected = true
        
        didToggleSelection?(!selectedItems.isEmpty)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        // update ViewModel item
        users[indexPath.row].isSelected = false
        
        didToggleSelection?(!selectedItems.isEmpty)
    }
}

extension ParticipantViewModel {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadMoreUsers?()
    }
}
