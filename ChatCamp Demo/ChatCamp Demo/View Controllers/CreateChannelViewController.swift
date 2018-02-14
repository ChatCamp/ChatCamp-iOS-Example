//
//  CreateChannelViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 11/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

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
    
    @IBOutlet weak var participantsTextField: UITextField!
    @IBOutlet weak var isDistinctCheckboxImageView: UIImageView!
    @IBOutlet weak var isDistinctCheckboxButton: UIButton!
    var isDistinct = false {
        didSet {
            isDistinctCheckboxImageView.image = isDistinct ? #imageLiteral(resourceName: "checkbox_checked") : #imageLiteral(resourceName: "checkbox_unchecked")
            isDistinctCheckboxButton.isSelected = isDistinct
        }
    }
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
        // TODO: write create channel logic
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapOnCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
