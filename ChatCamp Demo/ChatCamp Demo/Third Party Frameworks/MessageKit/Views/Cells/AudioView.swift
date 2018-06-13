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
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var audioTimeSlider: UISlider! {
        didSet {
            audioTimeSlider.setThumbImage(#imageLiteral(resourceName: "sliderthumb"), for: .normal)
        }
    }
    @IBOutlet weak var audioTimeLabel: UILabel! {
        didSet {
            audioTimeLabel.text = "00:00"
        }
    }
    
    var audioFileURL: URL!
    var audioPlayer: AVAudioPlayer?
    var displayLink : CADisplayLink! = nil
    var timeCount: Int = 0
    
    func playAudio(_ audioUrl: URL) {
        do {
            playButton.isSelected = !playButton.isSelected
            if playButton.isSelected {
                playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                if audioPlayer == nil {
                    audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
                    audioPlayer?.numberOfLoops = 0
                    audioPlayer?.delegate = self
                    audioPlayer?.play()
                } else {
                    audioPlayer?.play()
                }
                
                displayLink = CADisplayLink(target: self, selector: #selector(updateSliderProgress))
                displayLink.frameInterval = 1
                displayLink.add(to: .current, forMode: .commonModes)
            } else {
                playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
                audioPlayer?.pause()
                if displayLink != nil {
                    displayLink.invalidate()
                }
            }
        } catch {
            playButton.isSelected = !playButton.isSelected
            // couldn't load file :(
        }
    }
    
    func updateSliderProgress() {
        let progress = (audioPlayer?.currentTime)! / (audioPlayer?.duration)!
        timeCount += 1
        audioTimeLabel.text = NSString(format: "%02d:%02d", timeCount/3600, (timeCount/60)%60) as String
        audioTimeSlider.setValue(Float(progress), animated: false)
    }
}

extension AudioView: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.isSelected = !playButton.isSelected
        playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        displayLink.invalidate()
        timeCount = 0
    }
}
