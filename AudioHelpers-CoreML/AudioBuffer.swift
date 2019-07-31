//
//  AudioBuffer.swift
//  AudioHelpers-CoreML
//
//  Created by Rakeeb Hossain on 2019-07-30.
//  Copyright © 2019 Rakeeb Hossain. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import CoreAudio

class AudioBuffer: NSObject {
    
    var audioStreamFormat: AudioStreamBasicDescription!
    var inQueue: AudioQueueRef? = nil
    var audioBuffer: AudioQueueBuffer!
    
    struct BufferRecordSettings {
        let format: AudioFormatID = kAudioFormatLinearPCM
        let formatFlags: UInt32 = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        let sampleRate: Double = 16000.0
        let numChannels: UInt32 = 1
    }
    
    struct AQRecorderState {
        let mDataFormat: AudioStreamBasicDescription?
        let mQueue: AudioQueueRef?
        let mBuffers: [AudioQueueBufferRef]?
        let bufferByteSize: UInt32?
        let mCurrentPacket: UInt32?
        let mIsRunning: Bool?
    }
    
    var recordSettings = BufferRecordSettings()
    var aqData = AQRecorderState(mDataFormat: nil, mQueue: nil, mBuffers: nil, bufferByteSize: nil, mCurrentPacket: nil, mIsRunning: false)
    
    var isReady = false
    var isRecording = false
    var recordingStarted = false
    var recordingTime = CACurrentMediaTime()
    var elapsed = 0.0
    //func audioQueueInputCallback(ptr: Optional<UnsafeMutableRawPointer>?, queueRef: AudioQueueBufferRef, bufferRef: AudioQueueBufferRef, timePtr: UnsafePointer<AudioTimeStamp>, n: UInt32, packetInfo: Optional<UnsafePointer<AudioStreamPacketDescription>>) -> Void {}
    
    private let audioQueueInputCallback: AudioQueueInputCallback = {
        userData, queue, bufferRef, startTimeRef, numPackets, packetDescriptions in
        // Process your audio once it has completed
        print("Finished")
    }
    
    override init() {
        super.init()
        setUpAudio()
    }
    
    func setUpAudio() {
        audioStreamFormat = AudioStreamBasicDescription(
            mSampleRate: self.recordSettings.sampleRate,
            mFormatID: self.recordSettings.format,
            mFormatFlags: self.recordSettings.formatFlags,
            mBytesPerPacket: 2 * self.recordSettings.numChannels,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2 * self.recordSettings.numChannels,
            mChannelsPerFrame: self.recordSettings.numChannels,
            mBitsPerChannel: 16,
            mReserved: 0)
        
        print(audioStreamFormat!)
        let status = AudioQueueNewInput(&audioStreamFormat, audioQueueInputCallback, nil, nil, nil, 0, &inQueue)
        
        if (status == 0) {
            print("Setup successful")
            self.aqData = AQRecorderState(
                mDataFormat: audioStreamFormat,
                mQueue: inQueue!,
                mBuffers: [AudioQueueBufferRef](),
                bufferByteSize: 32,
                mCurrentPacket: 0,
                mIsRunning: false
            )
            isReady = true
        }
    }
    
    // Starts an indefinite audio recording
    public func startRecording() {
        if (!isReady) {
            print("Audio must be successfully initialized first")
        } else if (isRecording) {
            print("Audio already recording")
        } else {
            let status = AudioQueueStart(inQueue!, nil)
            if (status == 0) {
                recordingTime = CACurrentMediaTime()
                isRecording = true
                
                if (!recordingStarted) {
                    elapsed = 0
                    recordingStarted = true
                }
                print("Recording started...")
            } else {
                print("Failed to start recording")
            }
        }
    }
    
    // Starts an audio recording of fixed length; this cannot be paused or stopped; terminates automatically
    public func startRecording(milliseconds: Int, completionHandler: @escaping (Bool) -> Void) {
        if (!isReady) {
            print("Audio must be successfully initialized first")
        } else if (isRecording) {
            print("Audio already recording")
        } else {
            let status = AudioQueueStart(inQueue!, nil)
            if (status == 0) {
                recordingTime = CACurrentMediaTime()
                isRecording = true
                
                if (!recordingStarted) {
                    elapsed = 0
                    recordingStarted = true
                }
                print("Timed recording started...")
                
                DispatchQueue.global().async {
                    sleep(2)
                    let status = AudioQueueStop(self.inQueue!, true)
                    if (status == 0) {
                        self.isRecording = false
                        self.recordingStarted = false
                        print("Stopped timed recording.")
                        completionHandler(true)
                    } else {
                        print("Failed to stop timed recording.")
                        completionHandler(false)
                    }
                }
            } else {
                print("Failed to start timed recording.")
            }
        }
    }
    
    // Pauses currently playing audio recording
    public func pauseRecording() {
        if (!isReady) {
            print("Audio must be successfully initialized first")
        } else if (!isRecording) {
            print("Audio already paused/stopped")
        } else {
            let status = AudioQueuePause(inQueue!)
            if (status == 0) {
                isRecording = false
                elapsed += (CACurrentMediaTime() - recordingTime)
                recordingTime = 0
                print("Recording paused...")
            } else {
                print("Failed to start recording")
            }
        }
    }
    
    // Terminates currently playing audio recording
    public func stopRecording() {
        if (!isReady) {
            print("Audio must be successfully initialized first")
        } else {
            let status = AudioQueueStop(inQueue!, true)
            if (status == 0) {
                isRecording = false
                recordingStarted = false
                print("Stopped.")
            } else {
                print("Failed to stop.")
            }
        }
    }
}
