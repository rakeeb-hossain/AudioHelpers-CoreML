//
//  AudioHelpers.swift
//  UnityTest
//
//  Created by Rakeeb Hossain on 2019-07-24.
//  Copyright © 2019 Rakeeb Hossain. All rights reserved.
//

import UIKit
import Accelerate

var mY1: Float32 = 0.0
var mX1: Float32 = 0.0
var kAdjust0DB: Float32 = 1.5849e-13
let kDefaultPoleDist: Float32 = 0.975

func removeDCInplace(ioData: UnsafeMutablePointer<Float32>, numFrames: UInt32) {
    for i in 0..<Int(numFrames) {
        let xCurr = ioData[i]
        ioData[i] = ioData[i] - mX1 + (kDefaultPoleDist * mY1)
        mX1 = xCurr
        mY1 = ioData[i]
    }
}

func hanning(window: UnsafeMutablePointer<Float32>, numFrames: UInt32) {
    vDSP_hann_window(window, vDSP_Length(numFrames), Int32(vDSP_HANN_NORM))
}

class FFT: NSObject {
    // FFT declarations
    var bufferLog2: vDSP_Length!
    var fftSetup: FFTSetup!
    var fftLength: Int!
    var fftNormFactor: Float!
    var output: DSPSplitComplex!
    var numfftFrames: Int!
    
    func setup_fft(bufferLen: Int) {
        bufferLog2 = vDSP_Length(round(log2(Double(bufferLen/2))))
        fftSetup = vDSP_create_fftsetup(bufferLog2, FFTRadix(kFFTRadix2))
        fftLength = bufferLen/2
        fftNormFactor = 1.0 / Float(2 * bufferLen)
        output = DSPSplitComplex(
            realp: UnsafeMutablePointer.allocate(capacity: fftLength),
            imagp: UnsafeMutablePointer.allocate(capacity: fftLength)
        )
        numfftFrames = bufferLen
    }
    
    func fft(audioData: UnsafePointer<Float32>?, bufferLen: Int) -> [[Float]] {
        guard
            let audioData = audioData
        else { return [] }
        
        if (numfftFrames != bufferLen) {
            setup_fft(bufferLen: bufferLen)
        }
        // Allocate real and imaginary buffers
        audioData.withMemoryRebound(to: DSPComplex.self, capacity: fftLength) {inAudioDataPtr in
            vDSP_ctoz(inAudioDataPtr, 2, &output, 1, vDSP_Length(fftLength))
        }
        
        vDSP_fft_zrip(fftSetup!, &output, 1, bufferLog2, FFTDirection(kFFTDirection_Forward))
        vDSP_vsmul(output.realp, 1, &fftNormFactor, output.realp, 1, vDSP_Length(fftLength))
        vDSP_vsmul(output.imagp, 1, &fftNormFactor, output.imagp, 1, vDSP_Length(fftLength))
        
        // Filter out Nyquist value
        output.imagp[0] = 0.0
        
        return [Array(UnsafeBufferPointer(start: output.realp, count: fftLength)), Array(UnsafeBufferPointer(start: output.imagp, count: fftLength))]
    }

    func rfft(audioData: UnsafePointer<Float32>?, bufferLen: Int) -> [Float] {
        guard
            let audioData = audioData
        else { return [] }
        
        if (numfftFrames != bufferLen) {
            setup_fft(bufferLen: bufferLen)
        }
        
        // Allocate real and imaginary buffers
        audioData.withMemoryRebound(to: DSPComplex.self, capacity: fftLength) {inAudioDataPtr in
            vDSP_ctoz(inAudioDataPtr, 2, &output, 1, vDSP_Length(fftLength))
        }
        
        vDSP_fft_zrip(fftSetup!, &output, 1, bufferLog2, FFTDirection(kFFTDirection_Forward))
        vDSP_vsmul(output.realp, 1, &fftNormFactor, output.realp, 1, vDSP_Length(fftLength))
        
        // Filter out Nyquist value
        output.imagp[0] = 0.0
        
        return Array(UnsafeBufferPointer(start: output.realp, count: fftLength))
    }


    func fft_in_place(audioData: UnsafePointer<Float32>?, realData: UnsafeMutablePointer<Float32>?, imagData: UnsafeMutablePointer<Float32>?, bufferLen: Int) {
        guard
            let audioData = audioData
        else { return }
        
        if (numfftFrames != bufferLen) {
            setup_fft(bufferLen: bufferLen)
        }
        
        // Allocate real and imaginary buffers
        audioData.withMemoryRebound(to: DSPComplex.self, capacity: fftLength) {inAudioDataPtr in
            vDSP_ctoz(inAudioDataPtr, 2, &output, 1, vDSP_Length(fftLength))
        }
        
        vDSP_fft_zrip(fftSetup!, &output, 1, bufferLog2, FFTDirection(kFFTDirection_Forward))
        vDSP_vsmul(output.realp, 1, &fftNormFactor, realData!, 1, vDSP_Length(fftLength))
        vDSP_vsmul(output.imagp, 1, &fftNormFactor, imagData!, 1, vDSP_Length(fftLength))
        
        // Filter out Nyquist value
        imagData![0] = 0.0
    }

    func rfft_in_place(audioData: UnsafePointer<Float32>?, realData: UnsafeMutablePointer<Float32>?, bufferLen: Int) {
        guard
            let audioData = audioData
        else { return }
        
        if (numfftFrames != bufferLen) {
            setup_fft(bufferLen: bufferLen)
        }
        
        // Allocate real and imaginary buffers
        audioData.withMemoryRebound(to: DSPComplex.self, capacity: fftLength) {inAudioDataPtr in
            vDSP_ctoz(inAudioDataPtr, 2, &output, 1, vDSP_Length(fftLength))
        }
        
        vDSP_fft_zrip(fftSetup!, &output, 1, bufferLog2, FFTDirection(kFFTDirection_Forward))
        vDSP_vsmul(output.realp, 1, &fftNormFactor, realData!, 1, vDSP_Length(fftLength))
    }
    
    func calculateDecibels() -> [Float] {
        let dBData = UnsafeMutablePointer<Float>.allocate(capacity: fftLength)
        
        vDSP_zvmags(&output, 1, dBData, 1, vDSP_Length(fftLength))
        
        vDSP_vsadd(dBData, 1, &kAdjust0DB, dBData, 1, vDSP_Length(fftLength))
        var one: Float32 = 1
        vDSP_vdbcon(dBData, 1, &one, dBData, 1, vDSP_Length(fftLength), 0)
        
        return Array(UnsafeBufferPointer(start: dBData, count: fftLength))
    }
    
    func calculateDecibels_in_place(dBData: UnsafeMutablePointer<Float32>?) {
        guard
            let dBData = dBData
            else { return }
        
        vDSP_zvmags(&output, 1, dBData, 1, vDSP_Length(fftLength))
        
        vDSP_vsadd(dBData, 1, &kAdjust0DB, dBData, 1, vDSP_Length(fftLength))
        var one: Float32 = 1
        vDSP_vdbcon(dBData, 1, &one, dBData, 1, vDSP_Length(fftLength), 0)
    }
}
