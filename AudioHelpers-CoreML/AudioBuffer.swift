//
//  AudioBuffer.swift
//  AudioHelpers-CoreML
//
//  Created by Rakeeb Hossain on 2019-07-30.
//  Copyright © 2019 Rakeeb Hossain. All rights reserved.
//

import UIKit
import AVFoundation

class AudioBuffer: NSObject {
    
    var audioStreamFormat: AudioStreamBasicDescription!
    var inQueue: AudioQueueRef? = nil
    var audioBuffer: AudioQueueBuffer!
    
    struct BufferRecordSettings {
        let format: AudioFormatID = kAudioFormatAppleLossless
        let sampleRate: Double = 16000.0
        let bitRate: NSNumber = 320000
        let bitDepth: NSNumber = 16
        let numChannels: Int = 1
        let quality: AVAudioQuality = AVAudioQuality.medium
    }
    var recordSettings = BufferRecordSettings()
    
    //func audioQueueInputCallback(ptr: Optional<UnsafeMutableRawPointer>?, queueRef: AudioQueueBufferRef, bufferRef: AudioQueueBufferRef, timePtr: UnsafePointer<AudioTimeStamp>, n: UInt32, packetInfo: Optional<UnsafePointer<AudioStreamPacketDescription>>) -> Void {}
    
    private let audioQueueInputCallback: AudioQueueInputCallback = {
        userData, queue, bufferRef, startTimeRef, numPackets, packetDescriptions in
        
        print("Hi")
    }
    
    override init() {
        super.init()
        self.setUpAudio()
    }
    
    func setUpAudio() {
        audioStreamFormat = AudioStreamBasicDescription(
            mSampleRate: self.recordSettings.sampleRate,
            mFormatID: self.recordSettings.format,
            mFormatFlags: 0,
            mBytesPerPacket: UInt32(self.recordSettings.numChannels * MemoryLayout<UInt32>.size),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(self.recordSettings.numChannels * MemoryLayout<UInt32>.size),
            mChannelsPerFrame: UInt32(self.recordSettings.numChannels),
            mBitsPerChannel: UInt32(8 * (MemoryLayout<UInt32>.size)),
            mReserved: UInt32(0))
        AudioQueueNewInput(&audioStreamFormat, audioQueueInputCallback, nil, nil, nil, 0, &inQueue)
    }
}
