////
////  TSLibraryImport.swift
////  EasyPractice
////
////  Created by Bao Pham on 8/17/15.
////  Copyright © 2015 BaoPham. All rights reserved.
////
//
//import Foundation
//import AVFoundation
//
//class TSLibraryImport: TSLibraryImportInterface{
//    
//    var exportSession: AVAssetExportSession?
//    var TSLibraryImportErrorDomain: NSString = "TSLibraryImportErrorDomain"
//    
//    var TSUnknownError: NSString = "TUSUnknownError"
//    var TSFileExistsError: NSString = "TSFileExistsError"
//    
//    var kTSUnknownError: Int32 = 65536
//    var kTSFileExistsError: Int32 = 48
//    
//    var movieFileError: NSError?
//    
//    func validIpodLibraryURL(url: NSURL?) -> Bool{
//        let IPOD_SCHEME: NSString = "ipod-library"
//        if nil == url{ return false}
//        if nil == url?.scheme{ return false}
//        if url?.scheme.compare(IPOD_SCHEME as String) != NSComparisonResult.OrderedSame{ return false}
//        if url?.pathExtension?.compare("mp3") != NSComparisonResult.OrderedSame && url?.pathExtension?.compare("aif") != NSComparisonResult.OrderedSame && url?.pathExtension?.compare("m4a") != NSComparisonResult.OrderedSame && url?.pathExtension?.compare("wav") != NSComparisonResult.OrderedSame { return false}
//        
//        return true
//    }
//    
//    func extensionForAssetURL(assetURL: NSURL?) -> NSString{
//        if nil == assetURL{
//            NSException(name: NSInvalidArgumentException, reason: "nil assetURL", userInfo: nil)
//        }
//        if self.validIpodLibraryURL(assetURL){
//            NSException(name: NSInvalidArgumentException, reason: NSString(format: "Invalid iPod Library URL: %@", assetURL!) as String, userInfo: nil)
//        }
//        return (assetURL?.pathExtension)!
//    }
//    
//    func doMp3ImportToFile(destURL: NSURL, completeBlock: (imp: TSLibraryImport) -> Void){
//      let tmpURL: NSURL = (destURL.URLByDeletingPathExtension?.URLByAppendingPathExtension("mov"))!
//        do{ try NSFileManager.defaultManager().removeItemAtURL(tmpURL)}
//        catch{
//            error
//        }
//        exportSession!.outputURL = tmpURL
//        
//        exportSession!.outputFileType = AVFileTypeQuickTimeMovie
//        exportSession!.exportAsynchronouslyWithCompletionHandler({
//            if self.exportSession!.status == AVAssetExportSessionStatus.Failed{
//                completeBlock(imp: self)
//            } else if self.exportSession!.status == AVAssetExportSessionStatus.Cancelled{
//                completeBlock(imp: self)
//            } else {
//                do {try self.extractQuickTimeMovie(tmpURL, toFile: destURL)}
//                catch {
//                    let e: NSException?
//                    var code: OSStatus = noErr
//                    if (e?.name.compare(self.TSUnknownError as String) != nil){
//                        code = self.kTSUnknownError
//                    } else if e?.name.compare(self.TSFileExistsError as String) != nil{
//                        code = self.kTSFileExistsError
//                    }
//                    let errorDict: NSDictionary = NSDictionary(object: (e?.reason)!, forKey: NSLocalizedDescriptionKey)
//                    
//                    self.movieFileError = NSError(domain: self.TSLibraryImportErrorDomain as String, code: Int(code), userInfo: errorDict as [NSObject : AnyObject])
//                }
//                //clean up the tmp .mov file
//                do{ try NSFileManager.defaultManager().removeItemAtURL(tmpURL)}
//                catch{
//                    error
//                }
//            }
//            self.exportSession = nil
//        })
//    }
//    
//    func importAsset(assetURL: NSURL?, toURL: NSURL?, completionBlock: (imp: TSLibraryImport) -> Void){
//        if nil == assetURL || nil == toURL{
//            NSException(name: NSInvalidArgumentException, reason: "nil url", userInfo: nil)
//        }
//        if self.validIpodLibraryURL(assetURL) == false{
//            NSException(name: NSInvalidArgumentException, reason: NSString(format: "Invalid iPod Library URL: %@", assetURL!) as String, userInfo: nil)
//        }
//        if NSFileManager.defaultManager().fileExistsAtPath((toURL?.path)!){
//            NSException(name: TSFileExistsError as String, reason: NSString(format: "File already exist at url: %@", assetURL!) as String, userInfo: nil)
//        }
//        var options = NSDictionary()
//        var asset: AVURLAsset? = AVURLAsset(URL: assetURL!, options: options as! [String : AnyObject])
//        
//        if nil == asset{
//            NSException(name: TSUnknownError as String, reason: NSString(format: "Could not create AVURLAsset with url: %@", assetURL!) as String, userInfo: nil)
//        }
//        
//        exportSession = AVAssetExportSession(asset: asset!, presetName: AVAssetExportPresetPassthrough)
//        if nil == exportSession{
//            NSException(name: TSUnknownError as String, reason: NSString(format: "Couldn't create AVAssetExportSession %@", assetURL!) as String, userInfo: nil)
//        }
//        if assetURL?.pathExtension?.compare("mp3") == NSComparisonResult.OrderedSame{
//            self.doMp3ImportToFile(toURL!, completeBlock: completionBlock)
//            return
//        }
//        
//        exportSession?.outputURL = toURL
//        
//        //set the output file type approproately based on asset URL extension
//        
//        if assetURL?.pathExtension?.compare("m4a") == NSComparisonResult.OrderedSame{
//            exportSession?.outputFileType = AVFileTypeAppleM4A
//        }else if assetURL?.pathExtension?.compare("wav") == NSComparisonResult.OrderedSame{
//            exportSession?.outputFileType = AVFileTypeWAVE
//        }else if assetURL?.pathExtension?.compare("aif") == NSComparisonResult.OrderedSame{
//            exportSession?.outputFileType = AVFileTypeAIFF
//        }else{
//            NSException(name: NSInvalidArgumentException, reason: NSString(format: "unrecognized file extension %@", assetURL!) as String, userInfo: nil)
//        }
//        
//        exportSession?.exportAsynchronouslyWithCompletionHandler({
//            completionBlock(imp: self)
//            self.exportSession = nil
//        })
//    }
//    
//    func extractQuickTimeMovie(movieURL: NSURL, toFile: NSURL){
//        let src = fopen((movieURL.path?.cStringUsingEncoding(NSUTF8StringEncoding))!, "r")
//        if nil == src{
//            NSException(name: TSUnknownError as String, reason: NSString(format: "Counldn't open source file") as String, userInfo: nil)
//        }
//        var atom_name = [5]
//        atom_name[4] = '0'
//        var atom_size: ULONG = 0
//        while (true){
//            if let _ = feof(src){
//                break
//            }
//        }
//    }
//}