//
//  loopRangeSlider.swift
//  EasyPractice
//
//  Created by Bao Pham on 7/17/15.
//  Copyright © 2015 BaoPham. All rights reserved.
//

import UIKit
import QuartzCore

class LoopRangeSlider: UIControl { //UIControl because target action pattern will be used later instead of delegate pattern
    
    //for the slider
    var minimumValue: Float = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    //for the slider
    var maximumValue: Float = 1.0{
        didSet {
            updateLayerFrames()
        }
    }
    
    //lower thumb
    var lowerValue: Float = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    //upper thumb
    var upperValue: Float = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    let trackLayer = LoopRangeSliderTrackLayer()
    let lowerThumbLayer = LoopRangeSliderThumber()
    let upperThumbLayer = LoopRangeSliderThumber()
    
    var thumbWidth: CGFloat{
        return CGFloat(bounds.height)
    }
    
    var previousLocation = CGPoint()
    
    var trackTintColor: UIColor = UIColor.clearColor() {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    var trackHighlightTintColor: UIColor = UIColor.clearColor() {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    var thumbTintColor: UIColor = UIColor.orangeColor() {
        didSet {
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }
    
    var curvaceousness: CGFloat = 1.0 {
        didSet {
            trackLayer.setNeedsDisplay()
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }
    
    //add all the layers on the view
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        trackLayer.loopRangeSlider = self
        trackLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(trackLayer)
        
        lowerThumbLayer.loopRangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(lowerThumbLayer)
        
        upperThumbLayer.loopRangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(upperThumbLayer)
        
        updateLayerFrames()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //make sure all the frames fit the screen, update the frame everytime something is changed
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.frame = bounds.rectByInsetting(dx: 0.0, dy: bounds.height / 2.1)
        trackLayer.setNeedsDisplay()
        
        let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
        
        lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2.0, y: 0.0,
            width: thumbWidth, height: thumbWidth + 30)
        lowerThumbLayer.setNeedsDisplay()
        
        let upperThumbCenter = CGFloat(positionForValue(upperValue))
        upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth / 2.0, y: 0.0,
            width: thumbWidth, height: thumbWidth + 30)
        upperThumbLayer.setNeedsDisplay()
        
        CATransaction.commit() //the render will be smoother
    }
    
    //maps a value to a location on screen using a simple ratio to scale the position between the minimum and maximum range of the control.
    func positionForValue(value: Float) -> Float {
        //print(Float(thumbWidth))
        return Float(bounds.width - thumbWidth) * (value - minimumValue) /
            (maximumValue - minimumValue) + Float(thumbWidth / 2.0)
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        previousLocation = touch.locationInView(self)
        
        if lowerThumbLayer.frame.contains(previousLocation){
            lowerThumbLayer.highlighted = true
        } else if upperThumbLayer.frame.contains(previousLocation){
            upperThumbLayer.highlighted = true
        }
        
        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }
    
    func boundValue(value: Float, toLowerValue lowerValue: Float, upperValue: Float) -> Float {
        return Float(min(max(value, lowerValue), upperValue))
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        // 1. Determine by how much the user has dragged
        let deltaLocation = Float(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Float(bounds.width - thumbWidth)
        
        previousLocation = location
        
        // 2. Update the values
        if lowerThumbLayer.highlighted {
            lowerValue += deltaValue
            lowerValue = boundValue(lowerValue, toLowerValue: minimumValue, upperValue: upperValue)
        } else if upperThumbLayer.highlighted {
            upperValue += deltaValue
            upperValue = boundValue(upperValue, toLowerValue: lowerValue, upperValue: maximumValue)
        } else if upperThumbLayer.frame.contains(CGPoint(x: UIScreen.mainScreen().bounds.minX, y: UIScreen.mainScreen().bounds.midY - 20)){
            upperThumbLayer.frame.origin.x = upperThumbLayer.frame.origin.x + 1.0
            updateLayerFrames()
        }
        
        sendActionsForControlEvents(.ValueChanged) //notify the program when the location changes
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
    }

    //define the thumb
    class LoopRangeSliderThumber: CALayer {
        var highlighted: Bool = false {
            didSet {
                setNeedsDisplay()
            }
        }
        weak var loopRangeSlider: LoopRangeSlider?
        
        override func drawInContext(ctx: CGContext) {
            if let slider = loopRangeSlider {
                let thumbFrame = bounds.rectByInsetting(dx: 13.0, dy: 0.1)
                //let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
                let thumbPath = UIBezierPath(rect: thumbFrame)
                
                // Fill - with a subtle shadow
                let shadowColor = UIColor.grayColor()
                CGContextSetShadowWithColor(ctx, CGSize(width: 0.0, height: 1.0), 1.0, shadowColor.CGColor)
                CGContextSetFillColorWithColor(ctx, slider.thumbTintColor.CGColor)
                CGContextAddPath(ctx, thumbPath.CGPath)
                CGContextFillPath(ctx)
                
                // Outline
                CGContextSetStrokeColorWithColor(ctx, shadowColor.CGColor)
                CGContextSetLineWidth(ctx, 0.5)
                CGContextAddPath(ctx, thumbPath.CGPath)
                CGContextStrokePath(ctx)
                
                if highlighted {
                    CGContextSetFillColorWithColor(ctx, UIColor(white: 0.0, alpha: 0.1).CGColor)
                    CGContextAddPath(ctx, thumbPath.CGPath)
                    CGContextFillPath(ctx)
                }
            }
        }
    }
    
    //define the bar
    class LoopRangeSliderTrackLayer: CALayer {
        weak var loopRangeSlider: LoopRangeSlider?
        
        override func drawInContext(ctx: CGContext) {
            if let slider = loopRangeSlider {
                // Clip
                let cornerRadius = bounds.height * slider.curvaceousness / 2.0
                let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
                CGContextAddPath(ctx, path.CGPath)
                
                // Fill the track
                CGContextSetFillColorWithColor(ctx, slider.trackTintColor.CGColor)
                CGContextAddPath(ctx, path.CGPath)
                CGContextFillPath(ctx)
                
                // Fill the highlighted range
                CGContextSetFillColorWithColor(ctx, slider.trackHighlightTintColor.CGColor)
                let lowerValuePosition = CGFloat(slider.positionForValue(slider.lowerValue))
                let upperValuePosition = CGFloat(slider.positionForValue(slider.upperValue))
                let rect = CGRect(x: lowerValuePosition, y: 0.0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
                CGContextFillRect(ctx, rect)
            }
        }
    }
}