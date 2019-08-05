////////////////////////////////////////////////////////////////////
///                                                              ///
///   AudioHelpers-CoreML                                        ///
///                                                              ///
///   AudioCapture is a class that can be easily imported to a   ///
///   project for capturing audio to a file. The inputs and      ///
///   outputs can be customized accordingly.                     ///
///                                                              ///
////////////////////////////////////////////////////////////////////

import UIKit
import AVFoundation
import AudioToolbox
import CoreAudio

@objc protocol AURenderCallbackDelegate {
    func performRender(ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                       inTimeStamp: UnsafePointer<AudioTimeStamp>,
                       inBusNumber: UInt32,
                       inNumberFrames: UInt32,
                       ioData: UnsafeMutablePointer<AudioBufferList>)
}

public protocol AudioBufferControllerDelegate: class {
    func bufferFilled(inData: UnsafeMutablePointer<Float32>)
}

struct EffectState {
    var rioUnit: AudioUnit?
    var asbd: CAStreamBasicDescription?
    var sineFrequency: Float32?
    var sinePhase: Float32?
    var controllerInstance: UnsafeMutableRawPointer?
}

func InputModulatingRenderCallback(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBusNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    var effectState = inRefCon.assumingMemoryBound(to: EffectState.self)
    let delegate = unsafeBitCast(effectState.pointee.controllerInstance!, to: AURenderCallbackDelegate.self)
    delegate.performRender(ioActionFlags: ioActionFlags, inTimeStamp: inTimeStamp, inBusNumber: inBusNumber, inNumberFrames: inNumberFrames, ioData: ioData!)
    return noErr
}

@objc (AudioBuffer)
class AudioBufferController: NSObject, AURenderCallbackDelegate {
    
    let dataPtr = UnsafeMutablePointer<EffectState>.allocate(capacity: 1)
    weak var delegate: AudioBufferControllerDelegate?
    var bufferManager: BufferManager!
    var fft: FFT!
    var realData = [Float](repeating: 0.0, count: Int(4160/2))
    var imagData = [Float](repeating: 0.0, count: Int(4160/2))
    var recordSettings = RecordSettings()
    
    override init() {
        super.init()
        defer {dataPtr.deallocate()}
        dataPtr.initialize(to: EffectState())
        defer {dataPtr.deinitialize(count: 1)}

        let status = setupAudio(dataPtr)
        setupNotifications()
    }
    
    func setupAudio(_ dataPtr: UnsafeMutablePointer<EffectState>) -> Bool {
        // Init and setup recording session (AVAudioSession)
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

        } catch {
            print("Activating record session failed")
            return false
        }
        
        do {
            try recordingSession.setPreferredSampleRate(16000.0)
        } catch {
            print("Could not setup audio sample rate")
            return false
        }
        
        do {
            try recordingSession.setPreferredIOBufferDuration(0.005)
        } catch {
            print("Could not set buffer durations")
            return false
        }
        
        do {
            try recordingSession.setActive(true)
        } catch {
            print("Could not start recording session.")
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
        error = AudioComponentInstanceNew(rioComponent!, &dataPtr.pointee.rioUnit)
        if (error != 0) {
            print(String(error) + ": Couldn't get RIO unit instance")
            return false
        }
        
        // Sets up RIO unit for playback
        var oneFlag: UInt32 = 1
        let bus0: AudioUnitElement = 0
        error = AudioUnitSetProperty(dataPtr.pointee.rioUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, bus0, &oneFlag, UInt32(MemoryLayout.size(ofValue: oneFlag)))
        
        // Enable RIO input
        let bus1: AudioUnitElement = 1
        error = error | AudioUnitSetProperty(dataPtr.pointee.rioUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, bus1, &oneFlag, UInt32(MemoryLayout.size(ofValue: oneFlag)))
        
        if (error != 0) {
            print(String(error) + ": Couldn't enable RIO input/output")
            return false
        }
        
        // Setup stream format
        var ioFormat = CAStreamBasicDescription(sampleRate: 16000, numChannels: 1, pcmf: .float32, isInterleaved: false)
        error = AudioUnitSetProperty(dataPtr.pointee.rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Output), 1, &ioFormat, SizeOf32(ioFormat))
        error = error | AudioUnitSetProperty(dataPtr.pointee.rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Input), 0, &ioFormat, SizeOf32(ioFormat))

        // Setup the maximum number of sample frames the render callback can expect in each call of the render function
        var maxFramesPerSlice: UInt32 = 4160
        error = error | AudioUnitSetProperty(dataPtr.pointee.rioUnit!, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, bus0, &maxFramesPerSlice, SizeOf32(UInt32.self))
        
        if (error != 0) {
            print(String(error) + ": Couldn't set ASBD for RIO input/output")
            return false
        }
        
        var propSize = SizeOf32(UInt32.self)
        error = AudioUnitGetProperty(dataPtr.pointee.rioUnit!, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize)

        dataPtr.pointee.asbd = ioFormat
        dataPtr.pointee.sineFrequency = 30
        dataPtr.pointee.sinePhase = 0
        dataPtr.pointee.controllerInstance = Unmanaged.passUnretained(self).toOpaque()

        var callbackStruct = AURenderCallbackStruct(inputProc: InputModulatingRenderCallback, inputProcRefCon: dataPtr)
        error = AudioUnitSetProperty(dataPtr.pointee.rioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, bus0, &callbackStruct, UInt32(MemoryLayout.size(ofValue: callbackStruct)))
        
        if (error != 0) {
            print(String(error) + ": Couldn't set RIO's input callback on bus 0")
            return false
        }
        
        error = AudioUnitInitialize(dataPtr.pointee.rioUnit!)
        
        if (error != 0) {
            print(String(error) + ": Couldn't initialize the RIO unit")
            return false
        }
        
        fft = FFT()
        fft.setup_fft(nFrames: 4160)
        bufferManager = BufferManager(maxFramesPerSlice: Int(maxFramesPerSlice))
        print("Setup successful")

        return true
    }
    
    func performRender(ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp: UnsafePointer<AudioTimeStamp>, inBusNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>) -> Void {
        
        var ioPtr = UnsafeMutableAudioBufferListPointer(ioData)
        let bus1: UInt32 = 1
        var err = AudioUnitRender(dataPtr.pointee.rioUnit!, ioActionFlags, inTimeStamp, bus1, inNumberFrames, ioData)
        if err == noErr {
            bufferManager.memcpyAudioToFFTBuffer(ioPtr[0].mData!.assumingMemoryBound(to: Float32.self), inNumberFrames) { isBufferFilled, buffer in
                if isBufferFilled {
                    self.delegate?.bufferFilled(inData: buffer)
                }
            }
        }
        
        /*
        if (bufferManager.needsNewFFTData > 0) {
            bufferManager.memcpyAudioToFFTBuffer(ioPtr[0].mData!.assumingMemoryBound(to: Float32.self), inNumberFrames)
        }
        if (bufferManager.hasNewFFTData > 0) {
            fft.fft_in_place(ioPtr[0].mData!.assumingMemoryBound(to: Float32.self), realData: &realData, imagData: &imagData, nFrames: 4160)
            var a = fft.calculateDecibels()
        }
         */
        // At this point, you can either 1. save your buffers to the BufferManager class (in the case of getting the correctly-sized inputs for your CoreML model, THEN apply any effects), OR 2. you can apply the effects before in case you don't need a fixed size input
        
        // 1. Save to BufferManager, and when BufferManager's audiobuffer exceeds set size, apply effects and/or feed into model
        
        // 2. Apply effects immediately and feed into model
        
        //print(type(of: ioPtr[0].mData!.assumingMemoryBound(to: Float32.self)))
        
        // Looping through audio buffer bytes
        /*
        for buffer in ioPtr {
            let bufptr = UnsafeBufferPointer(start: buffer.mData!.assumingMemoryBound(to: Float32.self), count: Int(inNumberFrames))
            let arr = Array(bufptr)
            for i in arr {
                print(i)
            }
        }
         */
        
        
        // Removing DC component of audio waveform signal
        // bufferHelper.removeDCInplace(ioPtr[0].mData!.assumingMemoryBound(to: Float32.self), numFrames: inNumberFrames)
    }
    
    func setupNotifications() {
        // Handle interruptions
        let notificationCenter = NotificationCenter.default
    }
    
    func startRecording() {
        let status = AudioOutputUnitStart(dataPtr.pointee.rioUnit!)
        if status != noErr {
            print("Error: " + String(status))
        }
    }
    
    func stopRecording() {
        let status = AudioOutputUnitStop(dataPtr.pointee.rioUnit!)
        if status != noErr {
            print("Error: " + String(status))
        }
    }
}
