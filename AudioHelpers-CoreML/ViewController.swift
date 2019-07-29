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
    }
    
    @IBAction func StopButton(_ sender: UIButton) {
        audioCapture.stopRecording()
    }
    
    @IBAction func PauseButton(_ sender: UIButton) {
        audioCapture.pauseRecording()
    }
    
    var audioCapture: AudioCapture!
    let fileDir = "/Users/rakeeb/Desktop/"
    let filename = "audioFile.m4a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioCapture = AudioCapture(url: String(fileDir + filename))
        audioCapture.delegate = self
    }
}

extension ViewController: AudioCaptureDelegate {
    func didFinishRecording(_ capture: AudioCapture, _ success: Bool, _ duration: Double) {
        print(duration)
    }
}
