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

protocol AudioCaptureDelegate: class {
    func didFinishRecording(_ capture: AudioCapture, _ success: Bool, _ timestamp: CMTime)
}

class AudioCapture: NSObject {
    // weak var delegate = AudioCaptureDelegate?
    var recordingSession: AVAudioSession!
    var recorder: AVAudioRecorder!
    weak var delegate: AudioCaptureDelegate?
    
    var permissionGranted = false
    var isPlaying = false
    var audioIsReady = false
    var time = CACurrentMediaTime()
    
    let sessionQueue = DispatchQueue(label: "Audio queue")
    var audioSettings = RecordSettings()

    struct RecordSettings {
        let format: AudioFormatID = kAudioFormatAppleIMA4
        let sampleRate: NSNumber = 44100
        let bitRate: NSNumber = 12800
        let bitDepth: NSNumber = 16
        let quality: AVAudioQuality = AVAudioQuality.max
    }
    
    init(settings: RecordSettings, url: String) {
        super.init()
        self.audioSettings = settings
        print(self.audioSettings)
        setUpAudio(self.audioSettings, URL(string: url)!) { success in
            if success {
                self.audioIsReady = true
            } else {
                fatalError()
            }
        }
    }
    
    init(settings: RecordSettings) {
        super.init()
        self.audioSettings = settings
        print(self.audioSettings)
        setUpAudio(self.audioSettings, URL(string: Bundle.main.resourcePath!)!) { success in
            if success {
                self.audioIsReady = true
            } else {
                fatalError()
            }
        }
    }
    
    override init() {
        super.init()
        print(self.audioSettings)
        setUpAudio(self.audioSettings, URL(string: Bundle.main.resourcePath!)!) { success in
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
    
    public func configAudio(_ settings: RecordSettings, _ audioURL: URL) -> Bool {
        guard permissionGranted else {return false}
        // Recording session setup
        recordingSession = AVAudioSession.sharedInstance()
        do {
            #if swift(>=4.2)
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
            #elseif swift(>=4.0)
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
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
            AVEncoderAudioQualityKey: settings.quality
            ] as [String : Any]
        
        do {
            try recorder = AVAudioRecorder(url: audioURL, settings: r_settings)
        } catch {
            print("Could not setup audio recording with the supplied settings and/or output directory")
            return false
        }
        recorder.isMeteringEnabled = true
        
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
        }
    }
    
    // Starts an audio recording of fixed length; terminates automatically
    public func startRecording(ms: Int) {
        if (!audioIsReady) {
            print("Audio must be successfully initialized first")
        } else if (isPlaying) {
            print("Audio already recording")
        } else {
            recorder.record(forDuration: TimeInterval(ms))
        }
    }
    
    // Pauses currently playing audio recording
    public func pauseRecording() {
        if (!audioIsReady) {
            print("Audio must be successfully initialized first")
        } else if (!isPlaying) {
            print("Audio already paused")
        } else {
            isPlaying = false
            recorder.pause()
        }
    }
    
    // Terminates currently playing audio recording
    public func stopRecording() {
        if (!audioIsReady) {
            print("Audio must be successfully initialized first")
        } else {
            isPlaying = false
            recorder.stop()
        }
    }
}

extension AudioCapture: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // Handler for finished audio recording
    }
}
