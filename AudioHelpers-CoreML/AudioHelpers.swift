//
//  AudioHelpers.swift
//  UnityTest
//
//  Created by Rakeeb Hossain on 2019-07-24.
//  Copyright © 2019 Rakeeb Hossain. All rights reserved.
//

import UIKit
import Accelerate

class BufferHelper {
    private var mY1: Float32 = 0.0
    private var mX1: Float32 = 0.0

    private final let kDefaultPoleDist: Float32 = 0.975

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
}


public func fft() {
    
}
