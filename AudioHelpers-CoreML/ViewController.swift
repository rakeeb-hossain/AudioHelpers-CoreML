//
//  ViewController.swift
//  AudioHelpers-CoreML
//
//  Created by Rakeeb Hossain on 2019-07-26.
//  Copyright © 2019 Rakeeb Hossain. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBAction func RecordButton(_ sender: UIButton) {
        audioCapture.startRecording()
        scheduledTimerInterval()
        paused = false
    }
    
    @IBAction func StopButton(_ sender: UIButton) {
        timer.invalidate()
        audioCapture.stopRecording()
        TimeLabel.text = "0.00"
    }
    
    @IBAction func PauseButton(_ sender: UIButton) {
        timer.invalidate()
        audioCapture.pauseRecording()
        paused = true
    }
    @IBOutlet weak var TimeLabel: UILabel!
    var timer = Timer()
    var paused = false
    
    var audioCapture: AudioCapture!
    var audioBuffer: AudioBuffer!
    let filename = "/Users/rakeeb/Desktop/audioFile.m4a"
    let example = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if example == 1 {
            audioCapture = AudioCapture(url: String(filename))
            audioCapture.delegate = self
        }
        if example == 2 {
            audioBuffer = AudioBuffer()
        }
    }
    
    func scheduledTimerInterval() {
        // Set precision and frequency of timer
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: Selector("timerUpdate"), userInfo: nil, repeats: true)
    }
    
    @objc func timerUpdate() {
        if paused {
            let len = round(100*(audioCapture.elapsed - 0.001))/100
            TimeLabel.text = String(len)
        } else{
            let len = round(100*(CACurrentMediaTime() - audioCapture.recordingTime + audioCapture.elapsed - 0.001))/100
            TimeLabel.text = String(len)
        }
    }
}

extension ViewController: AudioCaptureDelegate {
    func didFinishRecording(_ capture: AudioCapture, _ success: Bool, _ duration: Double) {
        print(duration)
    }
}
