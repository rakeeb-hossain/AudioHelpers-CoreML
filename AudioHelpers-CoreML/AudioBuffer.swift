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

struct EffectState {
    var rioUnit: AudioUnit?
    var asbd: AudioStreamBasicDescription?
    var sineFrequency: Float32?
    var sinePhase: Float32?
}

func InputModulatingRenderCallback(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBusNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    return noErr
}

class AudioBuffer: NSObject {
    
    var effectState = EffectState(rioUnit: nil, asbd: nil, sineFrequency: nil, sinePhase: nil)
    
    override init() {
        super.init()
        let status = setupAudio()
        setupNotifications()
        
    }
    
    func setupAudio() -> Bool {
        // Init AVAudioSession
        var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
        var hardwareSampleRate: Double
        var error: OSStatus
        do {
            #if swift(>=4.2)
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            if (!recordingSession.isInputAvailable) {
                print("Audio input not available")
                return false
            }
            hardwareSampleRate = recordingSession.sampleRate
            
            #elseif swift(>=4.0)
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeDefault, options: AVAudioSessionCategoryOptions.defaultToSpeaker)
            #endif
            try recordingSession.setActive(true)
        } catch {
            print("Activating record session failed")
            return false
        }
        
        // Describe the audio unit
        var audioCompDesc: AudioComponentDescription = AudioComponentDescription()
        audioCompDesc.componentType = kAudioUnitType_Output
        audioCompDesc.componentSubType = kAudioUnitSubType_RemoteIO
        audioCompDesc.componentManufacturer = kAudioUnitManufacturer_Apple
        audioCompDesc.componentFlags = 0
        audioCompDesc.componentFlagsMask = 0
        
        let rioComponent = AudioComponentFindNext(nil, &audioCompDesc)
        error = AudioComponentInstanceNew(rioComponent!, &effectState.rioUnit)
        if (error != 0) {
            print(String(error) + ": Couldn't get RIO unit instance")
            return false
        }
        
        // Sets up RIO unit for playback
        var oneFlag: UInt32 = 1
        let bus0: AudioUnitElement = 0
        error = AudioUnitSetProperty(effectState.rioUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, bus0, &oneFlag, UInt32(MemoryLayout.size(ofValue: oneFlag)))
        
        // Enable RIO input
        let bus1: AudioUnitElement = 1
        error = error | AudioUnitSetProperty(effectState.rioUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, bus1, &oneFlag, UInt32(MemoryLayout.size(ofValue: oneFlag)))
        
        if (error != 0) {
            print(String(error) + ": Couldn't enable RIO input/output")
            return false
        }
        
        var myABSD = AudioStreamBasicDescription()
        print(hardwareSampleRate)
        myABSD.mSampleRate = 16000.0
        myABSD.mFormatID = kAudioFormatLinearPCM
        myABSD.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked
        myABSD.mBytesPerPacket = 2
        myABSD.mFramesPerPacket = 1
        myABSD.mBytesPerFrame = 2
        myABSD.mChannelsPerFrame = 1
        myABSD.mBitsPerChannel = 16
        
        error = AudioUnitSetProperty(effectState.rioUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, bus0, &myABSD, UInt32(MemoryLayout.size(ofValue: myABSD)))

        error = error | AudioUnitSetProperty(effectState.rioUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, bus0, &myABSD, UInt32(MemoryLayout.size(ofValue: myABSD)))

        if (error != 0) {
            print(String(error) + ": Couldn't set ASBD for RIO input/output")
            return false
        }
        
        effectState.asbd = myABSD
        effectState.sineFrequency = 30
        effectState.sinePhase = 0
        
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = InputModulatingRenderCallback
        callbackStruct.inputProcRefCon = nil
        error = AudioUnitSetProperty(effectState.rioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, bus0, &callbackStruct, UInt32(MemoryLayout.size(ofValue: callbackStruct)))
        
        if (error != 0) {
            print(String(error) + ": Couldn't set RIO's input callback on bus 0")
            return false
        }
        
        error = AudioUnitInitialize(effectState.rioUnit!)
        
        if (error != 0) {
            print(String(error) + ": Couldn't initialize the RIO unit")
            return false
        }
        print("Setup successful")
        // Set format for output (bus 0)
        return true
    }
    
    /*
    private let InputModulatingRenderCallback: AURenderCallback? = {  inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData in
        print("Finished")
        return(0)
    }
 */
    
    func setupNotifications() {
        // Handle interruptions
        let notificationCenter = NotificationCenter.default
    }
    
    func startRecording() {
        let status = AudioOutputUnitStart(effectState.rioUnit!)
        print(status)
    }
    
    func stopRecording() {
        let status = AudioOutputUnitStop(effectState.rioUnit!)
        print(status)
    }
    
    
    
    
    
    /*
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
 */
}
