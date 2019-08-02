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

func removeDCInplace(_ ioData: UnsafeMutablePointer<Float32>, numFrames: UInt32) {
    for i in 0..<Int(numFrames) {
        let xCurr = ioData[i]
        ioData[i] = ioData[i] - mX1 + (kDefaultPoleDist * mY1)
        mX1 = xCurr
        mY1 = ioData[i]
    }
}

func calculateDecibels(_ ioData: UnsafeMutablePointer<Float32>, numFrames: UInt32) -> Float32 {
    return 0.0
}

// FFT declarations
let bufferLog2: vDSP_Length = vDSP_Length(round(log2(Double(4160/2))))
let fftSetup = vDSP_create_fftsetup(bufferLog2, FFTRadix(kFFTRadix2))
let fftLength = 4160/2
var fftNormFactor = 1.0 / Float(2 * 4160)

var output = DSPSplitComplex(
    realp: UnsafeMutablePointer.allocate(capacity: fftLength),
    imagp: UnsafeMutablePointer.allocate(capacity: fftLength)
)

func fft(_ audioData: UnsafePointer<Float32>?) -> [[Float]] {
    guard
        let audioData = audioData
    else { return [] }
    
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

func rfft(_ audioData: UnsafePointer<Float32>?) -> [Float] {
    guard
        let audioData = audioData
    else { return [] }
    
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


func fft_in_place(_ audioData: UnsafePointer<Float32>?, realData: UnsafeMutablePointer<Float32>?, imagData: UnsafeMutablePointer<Float32>?, nFrames: Int) {
    guard
        let audioData = audioData
    else { return }
    
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

func rfft_in_place(_ audioData: UnsafePointer<Float32>?, realData: UnsafeMutablePointer<Float32>?, nFrames: Int) {
    guard
        let audioData = audioData
    else { return }
    
    // Allocate real and imaginary buffers
    audioData.withMemoryRebound(to: DSPComplex.self, capacity: fftLength) {inAudioDataPtr in
        vDSP_ctoz(inAudioDataPtr, 2, &output, 1, vDSP_Length(fftLength))
    }
    
    vDSP_fft_zrip(fftSetup!, &output, 1, bufferLog2, FFTDirection(kFFTDirection_Forward))
    vDSP_vsmul(output.realp, 1, &fftNormFactor, realData!, 1, vDSP_Length(fftLength))
}
