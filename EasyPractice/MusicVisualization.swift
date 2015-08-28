//
//  MusicVisualization.swift
//  EasyPractice
//
//  Created by Bao Pham on 7/27/15.
//  Copyright © 2015 BaoPham. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation

class MusicVisualization: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    var emitterLayer = CAEmitterLayer()
    var width = CGFloat()
    var height = CGFloat()
    var cell = CAEmitterCell()
    var childCell = CAEmitterCell()
    var audioPlayer: AVAudioPlayer?
    var dpLink = CADisplayLink()
    var meterTable = MeterTable()
    
    //layerClass() is a class method of UIView. You override this method when you want to change the underlying layer of your view class. Here you return the CAEmitterLayer class and UIKit ensures that self.layer returns an instance of CAEmitterLayer rather than the default CALayer.
    override class func layerClass() -> AnyClass {
        return CAEmitterLayer.self
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        //make sure that the self layer is in the correct type
        emitterLayer = self.layer as! CAEmitterLayer
    
        width = max(bounds.size.width, bounds.size.height)
        height = min(bounds.size.width, bounds.size.height)
        emitterLayer.emitterPosition = CGPointMake(width/2, height/2)
        emitterLayer.emitterSize = self.bounds.size //CGSizeMake(width-80, 60)
        emitterLayer.emitterShape = kCAEmitterLayerRectangle
        emitterLayer.renderMode = kCAEmitterLayerAdditive
        
        cell.name = "cell"
        //cell.contents = UIImage(named: "particleTexture")?.CGImage
        
        childCell.name = "childCell"
        childCell.lifetime = 1.0 / 60.0
        childCell.birthRate = 60.0
        childCell.velocity = 0.0
        
        childCell.contents = UIImage(named: "particleTexture")?.CGImage
        
        cell.emitterCells = [childCell]
        
        cell.color = UIColor(colorLiteralRed:1.0, green:0.53, blue:0.0, alpha:0.8).CGColor
        cell.redRange = 0.46
        cell.greenRange = 0.49
        cell.blueRange = 0.67
        cell.alphaRange = 0.55
        
        cell.redSpeed = 0.11
        cell.greenSpeed = 0.07
        cell.blueSpeed = 0.25
        cell.alphaSpeed = 0.05
        
        cell.scale = 0.5
        cell.scaleRange = 0.2
        
        cell.lifetime = 1.0
        cell.lifetimeRange = 0.25
        cell.birthRate = 100
        
        cell.velocity = 30.0
        cell.velocityRange = 60.0
        cell.emissionRange = CGFloat(M_PI * 2)
        
        //add cell into the emitterCells array
        emitterLayer.emitterCells = [cell]
        
        dpLink = CADisplayLink(target: self, selector: Selector("update"))
        dpLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    required init?(coder: NSCoder){ //when input is not correct
        super.init(coder: coder)
    }
    
    func update(){
        //print("\(audioPlayer.debugDescription)")
        var scale: Float = 0.5
        if let player = audioPlayer{
            if player.playing{
                print("Data Length: \(player.data?.length)")
                player.updateMeters()
                var power: Float = 0.0
                for var count = 0; count < player.numberOfChannels; count = count + 1{
                    power = power + player.averagePowerForChannel(count)
                }
                power = power / Float(player.numberOfChannels)
                NSLog("\(power)")
                
                let level: Float = (meterTable?.ValueAt(power))!
                scale = level * 8.0
                NSLog("\(level)")
                NSLog("\(player.url)")
            }
        }
        print("\(scale)")
        emitterLayer.setValue(scale, forKeyPath: "emitterCells.cell.emitterCells.childCell.scale")
    }
    
}


