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
        /*
        audioBuffer.startRecording(milliseconds: 2500) { success in
            if success {
                self.timer.invalidate()
                DispatchQueue.main.sync {
                    self.TimeLabel.text = "0.00"
                }
            }
        }*/
        audioBuffer.startRecording()
        //scheduledTimerInterval()
    }
    
    @IBAction func StopButton(_ sender: UIButton) {
        timer.invalidate()
        audioBuffer.stopRecording()
        TimeLabel.text = "0.00"
    }
    
    @IBAction func PauseButton(_ sender: UIButton) {
        timer.invalidate()
        //audioBuffer.pauseRecording()
    }
    
    @IBOutlet weak var TimeLabel: UILabel!
    var timer = Timer()
    
    var audioCapture: AudioCapture!
    var audioBuffer: AudioBufferController!
    let filename = "/Users/rakeeb/Desktop/audioFile.m4a"
    let example = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if example == 1 {
            audioCapture = AudioCapture(url: String(filename))
            audioCapture.delegate = self
        }
        if example == 2 {
            audioBuffer = AudioBufferController()
            audioBuffer.delegate = self
        }
    }
    /*
    func scheduledTimerInterval() {
        // Set precision and frequency of timer
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: Selector("timerUpdate"), userInfo: nil, repeats: true)
    }
    
    @objc func timerUpdate() {
        if !audioBuffer.isRecording {
            let len = round(100*(audioBuffer.elapsed - 0.001))/100
            TimeLabel.text = String(len)
        } else{
            let len = round(100*(CACurrentMediaTime() - audioBuffer.recordingTime + audioBuffer.elapsed - 0.001))/100
            TimeLabel.text = String(len)
        }
    }
 */
}

extension ViewController: AudioCaptureDelegate {
    func didFinishRecording(_ capture: AudioCapture, _ success: Bool, _ duration: Double) {
        print(duration)
    }
}

extension ViewController: AudioBufferControllerDelegate {
    func bufferFilled(inData: UnsafeMutablePointer<Float32>) {
        let bufferPtr = UnsafeBufferPointer(start: inData, count: 4160)
        let arr = Array(bufferPtr)
        print(arr.count)
    }
}
