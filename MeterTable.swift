//
//  MeterTable.swift
//  EasyPractice
//
//  Created by Bao Pham on 7/30/15.
//  Copyright © 2015 BaoPham. All rights reserved.
//

import Foundation

class MeterTable {
    
    func ValueAt(inDecibels: Float) -> Float {
        if inDecibels < mMinDecibels  {
            return 0.0
        }
        if inDecibels >= 0.0 {
            return 1.0
        }
        let index = Int(inDecibels * mScaleFactor)
        return mTable[index]
    }
    
    func getmDec() -> Float{
        return mMinDecibels
    }
    
    private var mMinDecibels: Float
    private var mDecibelResolution: Float
    private var mScaleFactor: Float
    private var mTable: [Float] = []
    
    private final class func DbToAmp(inDb: Double) -> Double {
        return pow(10.0, 0.05 * inDb)
    }
    
    // MeterTable constructor arguments:
    // inNumUISteps - the number of steps in the UI element that will be drawn.
    //					This could be a height in pixels or number of bars in an LED style display.
    // inTableSize - The size of the table. The table needs to be large enough that there are no large gaps in the response.
    // inMinDecibels - the decibel value of the minimum displayed amplitude.
    // inRoot - this controls the curvature of the response. 2.0 is square root, 3.0 is cube root. But inRoot doesn't have to be integer valued, it could be 1.8 or 2.5, etc.
    init?(minDecibels inMinDecibels: Float = -80.0, tableSize inTableSize: Int = 400, root inRoot: Float = 2.0) {
        mMinDecibels = inMinDecibels
        mDecibelResolution = mMinDecibels / Float(inTableSize - 1)
        mScaleFactor = 1.0 / mDecibelResolution
        if inMinDecibels >= 0.0 {
            print("MeterTable inMinDecibels must be negative", appendNewline: false)
            return nil
        }
        
        mTable = Array(count: inTableSize, repeatedValue: 0.0)
        
        let minAmp = MeterTable.DbToAmp(Double(inMinDecibels))
        let ampRange = 1.0 - minAmp
        let invAmpRange = 1.0 / ampRange
        
        let rroot = 1.0 / Double(inRoot)
        for i in 0..<inTableSize {
            let decibels = Double(i) * Double(mDecibelResolution)
            let amp = MeterTable.DbToAmp(decibels)
            let adjAmp = (amp - minAmp) * Double(invAmpRange)
            mTable[i] = Float(pow(adjAmp, rroot))
        }
    }
    
}