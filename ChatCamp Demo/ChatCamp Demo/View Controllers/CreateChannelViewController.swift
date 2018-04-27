//
//  CreateChannelViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 11/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp

class CreateChannelViewController: UIViewController {
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var createButton: UIBarButtonItem!
    
    @IBOutlet weak var optionOpen: UIButton! {
        didSet {
            optionOpen.isSelected = true
            optionOpen.layer.cornerRadius = 4
            optionOpen.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var optionGroup: UIButton! {
        didSet {
            optionGroup.layer.cornerRadius = 4
            optionGroup.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var participantsTextField: UITextField!
    @IBOutlet weak var isDistinctCheckboxImageView: UIImageView!
    @IBOutlet weak var isDistinctCheckboxButton: UIButton!
    var isDistinct = false {
        didSet {
            isDistinctCheckboxImageView.image = isDistinct ? #imageLiteral(resourceName: "checkbox_checked") : #imageLiteral(resourceName: "checkbox_unchecked")
            isDistinctCheckboxButton.isSelected = isDistinct
        }
    }
    var particpantList = [String]()
    var channelCreated: (() -> ())?
}

// MARK:- Actions
extension CreateChannelViewController {
    @IBAction func didTapOnOptionOpen(_ sender: UIButton) {
        if !sender.isSelected {
            sender.isSelected = true
            optionGroup.isSelected = false
        }
    }

    @IBAction func didTapOnOptionGroup(_ sender: UIButton) {
        if !sender.isSelected {
            sender.isSelected = true
            optionOpen.isSelected = false
        }
    }
    
    @IBAction func didTapOnIsDistinct(_ sender: UIButton) {
        isDistinct = !sender.isSelected
    }
    
    @IBAction func didTapOnCreate(_ sender: UIBarButtonItem) {
        let channelName = channelNameTextField.text ?? ""
        let participants = participantsTextField.text ?? ""
        let participantsArray = participants.components(separatedBy: ",")
        if channelName.isEmpty {
            showAlert(title: "Empty Channel Name!", message: "Channel Name cannot be blank", actionText: "OK")
            
            return
        }
        
        if participants.isEmpty || participantsArray.count == 1 {
            showAlert(title: "Empty Participants!", message: "Minimum 2 participant ids are required in comma seperated list to create a channel (e.g. 1, 2, 3).", actionText: "OK")

            return
        }
        
        if participantsArray.count > 1 {
            for participant in participantsArray {
                let element = participant.replacingOccurrences(of: " ", with: "")
                particpantList.append(element)
            }
        }
        
        
        if optionGroup.isSelected {
            CCPGroupChannel.create(name: channelName, userIds: particpantList, isDistinct: isDistinct) { groupChannel, error in
                if error == nil {
                    self.channelCreated?()
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.showAlert(title: "Error!", message: "Some error occured, please try again.", actionText: "OK")
                }
            }
        } else if optionOpen.isSelected {
            CCPOpenChannel.create(name: channelName) { openChannel, error in
                if error == nil {
                    self.channelCreated?()
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.showAlert(title: "Error!", message: "Some error occured, please try again.", actionText: "OK")
                }
            }
        }
    }
    
    @IBAction func didTapOnCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
