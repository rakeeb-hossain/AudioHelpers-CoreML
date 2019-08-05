//
//  BufferManager.swift
//  AudioHelpers-CoreML
//
//  Created by Rakeeb Hossain on 2019-08-02.
//  Copyright © 2019 Rakeeb Hossain. All rights reserved.
//

import UIKit

class BufferManager: NSObject {

    var mFFTInputBuffer: UnsafeMutablePointer<Float32>?
    private var mFFTInputBufferFrameIndex: Int
    private var mFFTInputBufferLoopingFrameIndex: Int
    private var mFFTInputBufferLen: Int
    let bufferSize = 4160
    
    var hasNewFFTData: Int32 = 0 // volatile
    var needsNewFFTData: Int32 = 1 // volatile

    var semaphore = DispatchSemaphore(value: 2)
    var semaphoreCounter: Int32 = 1
    
    init(maxFramesPerSlice: Int) {
        mFFTInputBufferLen = maxFramesPerSlice
        mFFTInputBufferFrameIndex = 0
        mFFTInputBufferLoopingFrameIndex = 0
        mFFTInputBuffer = UnsafeMutablePointer.allocate(capacity: maxFramesPerSlice)
    }
    
    deinit {
        mFFTInputBuffer?.deallocate()
    }
    
    func memcpyAudioToFFTBuffer(_ inData: UnsafeMutablePointer<Float32>, _ nFrames: UInt32, completion: @escaping (Bool, UnsafeMutablePointer<Float32>) -> Void) {
        let framesToCopy = Int(nFrames)
        memcpy(mFFTInputBuffer?.advanced(by: mFFTInputBufferFrameIndex*MemoryLayout<Float32>.size), inData, size_t(framesToCopy * MemoryLayout<Float32>.size))
        mFFTInputBufferFrameIndex += framesToCopy
        if mFFTInputBufferFrameIndex >= mFFTInputBufferLen {
            let bufptr: UnsafeMutablePointer<Float32> = UnsafeMutablePointer.allocate(capacity: mFFTInputBufferLen)
            memcpy(bufptr, mFFTInputBuffer, size_t(mFFTInputBufferLen * MemoryLayout<Float32>.size))
            mFFTInputBufferFrameIndex -= mFFTInputBufferLen
            completion(true, bufptr)
        } else {
            var arr: [Float32] = [0.0]
            completion(false, &arr)
        }
    }
}
