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
        let sampleRate: Double = 16000.0
        let bitRate: NSNumber = 320000
        let bitDepth: NSNumber = 16
        let numChannels: Int = 1
        let quality: AVAudioQuality = AVAudioQuality.medium
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
    var aqData = AQRecorderState(mDataFormat: nil, mQueue: nil, mBuffers: nil, bufferByteSize: nil, mCurrentPacket: nil, mIsRunning: nil)
    
    //func audioQueueInputCallback(ptr: Optional<UnsafeMutableRawPointer>?, queueRef: AudioQueueBufferRef, bufferRef: AudioQueueBufferRef, timePtr: UnsafePointer<AudioTimeStamp>, n: UInt32, packetInfo: Optional<UnsafePointer<AudioStreamPacketDescription>>) -> Void {}
    
    private let audioQueueInputCallback: AudioQueueInputCallback = {
        userData, queue, bufferRef, startTimeRef, numPackets, packetDescriptions in
        
        print("Hi")
    }

    override init() {
        super.init()
        setUpAudio()
        
        var status = AudioQueueStart(inQueue!, nil)
        print(status)
        DispatchQueue.global(qos: .background).async {
            sleep(4)
            status = AudioQueueStop(self.inQueue!, true)
            print(status)
        }
    }
    
    func setUpAudio() {
        audioStreamFormat = AudioStreamBasicDescription(
            mSampleRate: self.recordSettings.sampleRate,
            mFormatID: self.recordSettings.format,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0)
    
        let status = AudioQueueNewInput(&audioStreamFormat, audioQueueInputCallback, nil, nil, nil, 0, &inQueue)
        print(status)
        self.aqData = AQRecorderState(
            mDataFormat: audioStreamFormat,
            mQueue: inQueue!,
            mBuffers: [AudioQueueBufferRef](),
            bufferByteSize: 32,
            mCurrentPacket: 0,
            mIsRunning: true
        )
    }
}
