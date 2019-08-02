//
//  BufferManager.swift
//  AudioHelpers-CoreML
//
//  Created by Rakeeb Hossain on 2019-08-02.
//  Copyright © 2019 Rakeeb Hossain. All rights reserved.
//

import UIKit

class BufferManager: NSObject {

    private var mFFTInputBuffer: UnsafeMutablePointer<Float32>?
    private var mFFTInputBufferFrameIndex: Int
    private var mFFTInputBufferLen: Int
    
    var hasNewFFTData: Int32 = 0 // volatile
    var needsNewFFTData: Int32 = 1 // volatile
    
    init(maxFramesPerSlice: Int) {
        mFFTInputBufferLen = maxFramesPerSlice
        mFFTInputBufferFrameIndex = 0
        mFFTInputBuffer = UnsafeMutablePointer.allocate(capacity: maxFramesPerSlice)
    }
    
    deinit {
        mFFTInputBuffer?.deallocate()
    }
    
    func memcpyAudioToFFTBuffer(_ inData: UnsafeMutablePointer<Float32>, _ nFrames: UInt32) {
        let framesToCopy = min(Int(nFrames), mFFTInputBufferLen - mFFTInputBufferFrameIndex)
        if (framesToCopy != 0) {
            memcpy(mFFTInputBuffer?.advanced(by: mFFTInputBufferFrameIndex*MemoryLayout<Float32>.size), inData, size_t(framesToCopy*MemoryLayout<Float32>.size))
            mFFTInputBufferFrameIndex += framesToCopy
            if mFFTInputBufferFrameIndex >= mFFTInputBufferLen {
                print("Filled with: " + String(mFFTInputBufferFrameIndex) + " elements")
                OSAtomicIncrement32(&hasNewFFTData)
                OSAtomicDecrement32(&needsNewFFTData)
            }
        }
    }
}
