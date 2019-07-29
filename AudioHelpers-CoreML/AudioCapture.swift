////////////////////////////////////////////////////////////////////
///                                                              ///
///   AudioHelpers-CoreML                                        ///
///                                                              ///
///   AudioCapture is a class that can be easily imported to a   ///
///   project for capturing audio. The inputs and outputs can    ///
///   be customized accordingly.                                 ///
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
    
    let sessionQueue = DispatchQueue(label: "Audio queue")
    var audioSettings = [String: Any]()

    struct RecordSettings {
        
    }
    
    init(settings: [String: Any]) {
        super.init()
        self.audioSettings = settings
        print(self.audioSettings)
        setUpAudio { success in
            if success {
                self.audioIsReady = true
            }
        }
    }
    
    override init() {
        super.init()
        self.audioSettings = ["hey": 123]
        print(self.audioSettings)
        setUpAudio { success in
            if success {
                self.audioIsReady = true
            }
        }
    }
    
    func setUpAudio(completion: @escaping ((Bool) -> Void)) {
        checkPermission()
        sessionQueue.async {
            let success = self.configAudio()
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
    
    public func configAudio() -> Bool {
        guard permissionGranted else {return false}
        recordingSession = AVAudioSession.sharedInstance()
        do {
            #if swift(>=4.2)
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
            #elseif swift(>=4.0)
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            #endif
        } catch {
            print("Setting recording type failed")
            return false
        }
        //recordingSession.setActive(true, options: audioOptions)
        
        return true
        
    }
    
    // Starts an indefinite audio recording
    public func startSample() {
        
    }
    
    // Starts an audio recording of fixed length; terminates automatically
    public func startSample(ms: Int) {
        
    }
    
    // Terminates currently playing audio recording
    public func stopSample() {
        
    }
}

extension AudioCapture: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // Handler for finished audio recording
    }
}
