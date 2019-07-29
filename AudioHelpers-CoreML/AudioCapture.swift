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

class AudioCapture: NSObject {
    // weak var delegate = AudioCaptureDelegate?
    var recordingSession: AVAudioSession!
    var recorder: AVAudioRecorder!
    
    var permissionGranted = false
    var isPlaying = false
    
    let sessionQueue = DispatchQueue(label: "Audio queue")

    public struct CaptureType {}
    
    override init() {
        super.init()
        setUpAudio { success in
            if success {
                // start audio
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
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
        } catch {
            print("Setting recording type failed")
            return false
        }
        //recordingSession.setActive(true, options: audioOptions)
        
        return true
        
    }
    
    // Starts an indefinite audio recording
    public func startSample(id: Int) {
        
    }
    
    // Starts an audio recording of fixed length; terminates automatically
    public func startSample(ms: Int, id: Int) {
        
    }
    
    // Terminates audio recordings of a given ID
    public func endSample(id: Int) {
        
    }
    
    // Terminates all audio recordings
    public func endAllSamples() {
        
    }
}
