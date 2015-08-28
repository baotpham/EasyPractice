//
//  DrawingWaveform.swift
//  EasyPractice
//
//  Created by Bao Pham on 8/4/15.
//  Copyright © 2015 BaoPham. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class DrawingWaveform: UIView{
    
//    init(withFilePath: NSString) {
//        
//        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
   
    //rendering method
    func audioImageGraph(sample: Int16, normalizeMax: Int16, sampleCount: NSInteger, channelCount: NSInteger, imageHeight: Float) -> UIImage{
        
        //create an environment to draw on
        let imageSize = CGSizeMake(CGFloat(sampleCount),CGFloat(imageHeight))
        UIGraphicsBeginImageContext(imageSize)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        
        //set the color and the location
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextSetAlpha(context, 1.0)
        var rect = CGRect()
        rect.size = imageSize
        rect.origin.x = 0.0
        rect.origin.y = 0.0
        
        //color for each channel
        let leftColor: CGColorRef = UIColor.whiteColor().CGColor
        let rightColor: CGColorRef = UIColor.redColor().CGColor
        
        //place a rect in the context
        CGContextFillRect(context, rect)
        CGContextSetLineWidth(context, 1.0)
        
        //initialize some constant
        let halfGraphHeight: Float = (imageHeight/2) / Float(channelCount)
        let centerLeft: Float = halfGraphHeight
        let centerRight: Float = halfGraphHeight * 3
        let sampleAdjustmentFactor = (imageHeight / Float(channelCount)) / Float(normalizeMax)
        
        //draw waves for two channel
        for var intSample = 0; intSample < sampleCount; intSample = intSample + 1{
            let left: Int16 = sample + sample
            var pixels: Float = Float(left)
            pixels = pixels * sampleAdjustmentFactor
            CGContextMoveToPoint(context, CGFloat(intSample), CGFloat(centerLeft - pixels))
            CGContextAddLineToPoint(context, CGFloat(intSample), CGFloat(centerLeft + pixels))
            CGContextSetStrokeColorWithColor(context, leftColor)
            CGContextStrokePath(context)
            
            if(channelCount == 2){
                let right: Int16 = sample + sample
                var pixels: Float = Float(right)
                pixels = pixels * sampleAdjustmentFactor
                CGContextMoveToPoint(context, CGFloat(intSample), CGFloat(centerRight - pixels))
                CGContextAddLineToPoint(context, CGFloat(intSample), CGFloat(centerRight + pixels))
                CGContextSetStrokeColorWithColor(context, rightColor)
                CGContextStrokePath(context)
            }
        }
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        NSLog("\(newImage)")
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    //takes a AVURLAsset, and returns PNG image data
    func renderPNGAudioPictogramForAsset(songAsset: AVURLAsset) -> NSData?{
        
        //var error: NSError?
        var reader: AVAssetReader?
        do{ reader = try AVAssetReader(asset: songAsset)}
        catch{
            error
        }
        
        //store track
        let songTrack: AVAssetTrack = songAsset.tracks[0]
        
        //define what kind of information to output
        let outputSettingDict: NSDictionary = [ NSNumber(int: 16) : AVLinearPCMBitDepthKey,
                                                NSNumber(bool: false) : AVLinearPCMIsBigEndianKey,
                                                NSNumber(bool: false) : AVLinearPCMIsFloatKey,
                                                NSNumber(bool: false) : AVLinearPCMIsNonInterleaved]
        
        //determine what is the output
        let output = AVAssetReaderTrackOutput(track: songTrack, outputSettings: outputSettingDict as? [String : AnyObject])
        
        //will output "output"
        reader?.addOutput(output)
        
        var sampleRate: UInt32?
        var channelCount: UInt32?
        
        //format of the sample (audio, video, and so on)
        let formatDesc: NSArray = songTrack.formatDescriptions
        
        //set sampleRate and channelCount for each item in the formatDesc
        for var i = 0; i < formatDesc.count; i = i + 1 {
            let item: CMAudioFormatDescriptionRef = formatDesc.objectAtIndex(i) as! CMAudioFormatDescriptionRef
            let fmtDesc: AudioStreamBasicDescription? = CMAudioFormatDescriptionGetStreamBasicDescription(item).memory
            if let desc = fmtDesc{
                sampleRate = UInt32(desc.mSampleRate)
                channelCount = desc.mChannelsPerFrame
            }
        }
        
        let bytesPerSample: UInt32 = 2 * channelCount!
        var normalizeMax: Int16 = 0
        
        let fullSongData = NSMutableData()
        reader?.startReading()
        
        var totalBytes: UInt64 = 0
        var totalLeft: Int64 = 0
        var totalRight: Int64 = 0
        var sampleTally: Int = 0
        
        let samplesPerPixel: Int = Int(sampleRate! / 50)
        //calculate all other variables above
        while reader?.status == AVAssetReaderStatus.Reading{
            let trackOutput: AVAssetReaderTrackOutput = reader?.outputs[0] as! AVAssetReaderTrackOutput
            let sampleBufferRef: CMSampleBufferRef? = trackOutput.copyNextSampleBuffer()
            
            if let sampleBuff = sampleBufferRef{
                let blockBufferRef: CMBlockBufferRef? = CMSampleBufferGetDataBuffer(sampleBuff)
                if blockBufferRef != nil{
                    let length: size_t = CMBlockBufferGetDataLength(blockBufferRef!)
                    totalBytes = totalBytes + UInt64(length)
                autoreleasepool{
                    let data: NSMutableData? = NSMutableData(length: length)
                    CMBlockBufferCopyDataBytes(blockBufferRef!, 0, length, data!.mutableBytes)
                    
                    let samples: Int64 = Int64(data!.bytes.memory)
                    let sampleCount = length / Int(bytesPerSample)
                    
                    for var i = 0; i < sampleCount ; i = i + 1{
                    
                        var left: Int16 = Int16(samples) + 1
                        totalLeft  = totalLeft + Int64(left)
                    
                        var right: Int16
                        if channelCount == 2 {
                            right = Int16(samples) + 1
                            totalRight = totalRight + Int64(right)
                        }
                    
                        sampleTally++;
                    
                        if sampleTally > samplesPerPixel {
                        
                           left  = Int16(totalLeft / Int64(sampleTally))
                        
                            let fix: Int16 = Int16(abs(left))
                            if fix > normalizeMax {
                            normalizeMax = fix
                            }
                        
                            fullSongData.appendBytes(&left, length: sizeofValue(left))
                        
                            if (channelCount==2) {
                                right = Int16(totalRight / Int64(sampleTally))
                            
                                let fix: Int16 = Int16(abs(right))
                                if (fix > normalizeMax) {
                                    normalizeMax = fix;
                                }
                                fullSongData.appendBytes(&right, length: sizeofValue(right))
                            }
                            totalLeft   = 0
                            totalRight  = 0
                            sampleTally = 0
                        }
                    }
                }
                CMSampleBufferInvalidate(sampleBufferRef!);
                }
            }
        }
        
            var finalData: NSData?
            if reader?.status == AVAssetReaderStatus.Failed || reader?.status == AVAssetReaderStatus.Unknown{
                return nil
            }
        
            if reader?.status == AVAssetReaderStatus.Completed{
            
                NSLog("rendering output graphics using normalizeMax %d",normalizeMax)
            
                let test: UIImage = self.audioImageGraph(Int16(fullSongData.bytes.memory), normalizeMax: normalizeMax, sampleCount: fullSongData.length / 4, channelCount: 2,imageHeight: Float(100.0))
            
                finalData = UIImagePNGRepresentation(test)
                
        }
        return finalData!
    }
    
    
    //-----------------------------------------------------------------------------------------------------
    //handling path names
    
    let imgExt: NSString = "png"
    
    //search for the path of the directory
    func assetCacheFolder() -> NSString{
        var assetFolderRoot = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        return NSString(format: "%@/audio", assetFolderRoot[0])
    }
    
    //information for path of the directory and the ID for the pictogram
    func cachedAudioPictogramPathForMPMEdiaItem(item: MPMediaItem) -> NSString{
        let assetFolder: NSString = self.assetCacheFolder()
        let libraryId: NSNumber = item.valueForProperty(MPMediaItemPropertyPersistentID) as! NSNumber
        let assetPictogramFilename: NSString = NSString(format: "asset_%@.%@", libraryId, imgExt)
        return NSString(format: "%@/%@", assetFolder, assetPictogramFilename)
    }
    
    //information for path of the directory and the ID for the file
    func cachedAudioFilepathForMPMediaItem(item: MPMediaItem) -> NSString{
        let assetFolder: NSString = self.assetCacheFolder()
        
        let assetURL: NSURL = item.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL
        let libraryId: NSNumber = item.valueForProperty(MPMediaItemPropertyPersistentID) as! NSNumber
        
        let assetFileExt: NSString = assetURL.pathExtension!
        let assetFilename: NSString = NSString(format: "asset_%@.%@", libraryId, assetFileExt)
        return NSString(format: "%@/%@", assetFolder, assetFilename)
    }
    
    //return the URL of the file
    func cachedAudioURLForMPMediaItem(item: MPMediaItem) -> NSURL{
        let assetFilepath = self.cachedAudioFilepathForMPMediaItem(item)
        return NSURL(fileURLWithPath: assetFilepath as String)
    }
    
    
    //-------------------------------------------------------------------------------------------------------
    
    var finalPic: UIImage?
    var x: Int = 0
    func initWithMPMediaItem(item: MPMediaItem, completionBlock: (delayedImagePreparation: UIImage) -> Void) -> AnyObject?{
        let fman: NSFileManager = NSFileManager.defaultManager()
        let assetPictogramFilepath = self.cachedAudioPictogramPathForMPMEdiaItem(item)
        
        
        let assetFilePath: NSString = self.cachedAudioFilepathForMPMediaItem(item)
        
        let assetFileURL: NSURL = NSURL(fileURLWithPath: assetFilePath as String)

        if fman.fileExistsAtPath(assetFilePath as String){
            NSLog("scanning cached audio data to create UIImage file: %@", assetFilePath.lastPathComponent);
            
            //throw it on the queue for later.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),{
                let asset: AVURLAsset = AVURLAsset(URL: assetFileURL, options: nil)
            
                let waveformData: NSData = self.renderPNGAudioPictogramForAsset(asset)!
                
                waveformData.writeToFile(assetPictogramFilepath as String, atomically: true)
                
                if let _ = self.initWithMPMediaItem(item, completionBlock: { (delayedImagePreparation) -> Void in
                    print("hi")
                }){
                    //sync because the program needs to wait until this code is executed
                    dispatch_sync(dispatch_get_main_queue(),{
                        let result: UIImage = UIImage(data: waveformData)!
                        NSLog("returning rendered pictogram on main thread (%d bytes %@ data in UIImage %0.0f x %0.0f pixels)", waveformData.length,self.imgExt.uppercaseString,result.size.width,result.size.height)
                        completionBlock(delayedImagePreparation: result)
                    })
                }
            })
            return nil
        }else{
            let assetFolder: NSString = self.assetCacheFolder()
            do {try fman.createDirectoryAtPath(assetFolder as String, withIntermediateDirectories: true, attributes: nil)}
            catch{
                error
            }
            
            NSLog("Preparing to import audio asset data %@", assetFilePath.lastPathComponent)
            
//            TSLibraryImport* import = [[TSLibraryImport alloc] init];
//            NSURL    * assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
//            
//            [import importAsset:assetURL toURL:assetFileURL completionBlock:^(TSLibraryImport* import) {
//            //check the status and error properties of
//            //TSLibraryImport
//            
//            if (import.error) {
//            
//            NSLog (@"audio data import failed:%@",import.error);

            NSLog("Creating waveform pictogram file: %@", assetPictogramFilepath.lastPathComponent)
            
            let asset: AVURLAsset = AVURLAsset(URL: item.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL, options: nil)
            
            let waveformData: NSData = self.renderPNGAudioPictogramForAsset(asset)!
            
            waveformData.writeToFile(assetPictogramFilepath as String, atomically: true)
            
            if let _ = self.initWithMPMediaItem(item, completionBlock: { (delayedImagePreparation) -> Void in
                print("hi")
            }) {
                dispatch_sync(dispatch_get_main_queue(),{
                    let result: UIImage = UIImage(data: waveformData)!
                    NSLog("returning rendered pictogram on main thread (%d bytes %@ data in UIImage %0.0f x %0.0f pixels)", waveformData.length, self.imgExt.uppercaseString, result.size.width, result.size.height)
                    self.finalPic = result
                    self.x = 1
                    self.initWithMPMediaItem(item, completionBlock: { (delayedImagePreparation) -> Void in
                        print("done")
                    })
                    completionBlock(delayedImagePreparation: result)
                })
            }
            
        }
        if fman.fileExistsAtPath(assetPictogramFilepath as String){
            NSLog("Returning cached waveform pictogram: %@", assetPictogramFilepath.lastPathComponent)
            return self
        }
        
        return nil
    }
}


    //http://stackoverflow.com/questions/5032775/drawing-waveform-with-avassetreader

