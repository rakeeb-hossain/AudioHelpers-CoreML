////////////////////////////////////////////////////////////////////
///                                                              ///
///   AudioHelpers-CoreML                                        ///
///                                                              ///
///   AudioCapture is a class that can be easily imported to a   ///
///   project for capturing audio to a file. The inputs and      ///
///   outputs can be customized accordingly.                     ///
///                                                              ///
////////////////////////////////////////////////////////////////////


/* Find a way to extract audio features
 
 1) Compactness.
 2) Magnitude spectrum.
 3) Mel-frequency cepstral coefficients.
 4) Pitch.
 5) Power Spectrum.
 6) RMS.
 7) Rhythm.
 8) Spectral Centroid.
 9) Spectral Flux.
 10) Spectral RollOff Point.
 11) Spectral Variability.
 12) Zero Crossings.
 
*/

import UIKit
import AVFoundation

public protocol AudioCaptureDelegate: class {
    func didFinishRecording(_ capture: AudioCapture, _ success: Bool, _ duration: Double)
}

public class AudioCapture: NSObject {
    var recorder: AVAudioRecorder!
    weak var delegate: AudioCaptureDelegate?
    
    var permissionGranted = false
    var isPlaying = false
    var recordingStarted = false
    var audioIsReady = false
    var recordingTime = CACurrentMediaTime()
    var elapsed = 0.0
    
    let sessionQueue = DispatchQueue(label: "Audio queue")
    var defaultAudioSettings = RecordSettings()

    struct RecordSettings {
        let format: AudioFormatID = kAudioFormatAppleLossless
        let sampleRate: NSNumber = 16000.0
        let bitRate: NSNumber = 320000
        let bitDepth: NSNumber = 16
        let numChannels: Int = 1
        let quality: AVAudioQuality = AVAudioQuality.medium
    }
    
    init(settings: RecordSettings, url: String) {
        super.init()
        setUpAudio(settings, URL(string: url)!) { success in
            if success {
                self.audioIsReady = true
            } else {
                fatalError()
            }
        }
    }
    
    init(settings: RecordSettings) {
        super.init()
        setUpAudio(settings, URL(string: Bundle.main.resourcePath!)!) { success in
            if success {
                self.audioIsReady = true
            } else {
                fatalError()
            }
        }
    }
    
    init(url: String) {
        super.init()
        setUpAudio(self.defaultAudioSettings, URL(string: url)!) { success in
            if success {
                self.audioIsReady = true
            } else {
                fatalError()
            }
        }
    }

    
    override init() {
        super.init()
        setUpAudio(self.defaultAudioSettings, URL(string: Bundle.main.resourcePath!)!) { success in
            if success {
                self.audioIsReady = true
            } else {
                fatalError()
            }
        }
    }
    
    func setUpAudio(_ settings: RecordSettings, _ audioURL: URL, completion: @escaping ((Bool) -> Void)) {
        checkPermission()
        sessionQueue.async {
            let success = self.configAudio(settings, audioURL)
            // Enable this if you are calling setUpAudio from your viewController
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.audio) { granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
        case .authorized:
            permissionGranted = true
        case .denied:
            permissionGranted = false
        case .notDetermined:
            requestPermission()
        case .restricted:
            permissionGranted = false
        @unknown default:
            fatalError()
        }
    }
    
    func configAudio(_ settings: RecordSettings, _ audioURL: URL) -> Bool {
        guard permissionGranted else {return false}
        // Recording session setup
        var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            #if swift(>=4.2)
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            #elseif swift(>=4.0)
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeDefault, options: AVAudioSessionCategoryOptions.defaultToSpeaker)
            #endif
            try recordingSession.setActive(true)
        } catch {
            print("Activating record session failed")
            return false
        }
        
        // Recorder setup
        let r_settings = [
            AVFormatIDKey: settings.format,
            AVSampleRateKey: settings.sampleRate,
            AVEncoderBitRateKey: settings.bitRate,
            AVLinearPCMBitDepthKey: settings.bitDepth,
            AVNumberOfChannelsKey: settings.numChannels,
            AVEncoderAudioQualityKey: settings.quality.rawValue
        ] as [String : Any]
        
        do {
            try recorder = AVAudioRecorder(url: audioURL, settings: r_settings)
        } catch {
            print("Could not setup audio recording with the supplied settings and/or output directory")
            return false
        }
        //recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        return true
        
    }
    
    // Starts an indefinite audio recording
    public func startRecording() {
        if (!audioIsReady) {
            print("Audio must be successfully initialized first")
        } else if (isPlaying) {
            print("Audio already recording")
        } else {
            isPlaying = true
            recorder.record()
            print("Recording")
            recordingTime = CACurrentMediaTime()
            elapsed = 0

            if (!recordingStarted) {
                recordingStarted = true
            }
        }
    }
    
    // Starts an audio recording of fixed length; terminates automatically
    public func startRecording(ms: Int) {
        if (!audioIsReady) {
            print("Audio must be successfully initialized first")
        } else if (isPlaying) {
            print("Audio already recording")
        } else {
            isPlaying = true
            recorder.record(forDuration: TimeInterval(ms))
            recordingTime = CACurrentMediaTime()

            if (!recordingStarted) {
                recordingStarted = true
            }
        }
    }
    
    // Pauses currently playing audio recording
    public func pauseRecording() {
        if (!audioIsReady) {
            print("Audio must be successfully initialized first")
        } else if (!isPlaying) {
            print("Audio already paused/stopped")
        } else {
            isPlaying = false
            recorder.pause()
            elapsed += (CACurrentMediaTime() - recordingTime)
            recordingTime = 0
        }
    }
    
    // Terminates currently playing audio recording
    public func stopRecording() {
        if (!audioIsReady) {
            print("Audio must be successfully initialized first")
        } else {
            isPlaying = false
            recordingStarted = false
            recorder.stop()
            print("Stopped")
        }
    }
}

extension AudioCapture: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // Handler for finished audio recording
        print("FINISHED")
        delegate?.didFinishRecording(self, true, (CACurrentMediaTime() - self.recordingTime + elapsed))
    }
}
