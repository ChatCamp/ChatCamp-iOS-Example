//
//  AudioView.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 12/06/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import AVFoundation

class AudioView: UIView {
    
    var audioFileURL: URL!
    var audioPlayer: AVAudioPlayer?
    
    func playAudio(_ audioUrl: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            audioPlayer?.play()
        } catch {
            // couldn't load file :(
        }
    }
}
