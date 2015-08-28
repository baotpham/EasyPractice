//
//  NSThread+MCSMAdditions.swift
//  EasyPractice
//
//  Created by Bao Pham on 8/14/15.
//  Copyright © 2015 BaoPham. All rights reserved.
//

import Foundation

extension NSThread {
    
    
    func MCSM_performBlockOnMainThread(block: () -> Void) -> Void{
        NSThread.mainThread().MCSM_performBlock(block)
    }
    
    func MCSM_performBlockInBackground(block: () -> Void){
        NSThread.performSelectorInBackground(Selector("MCSM_runBlock"), withObject: (block as! AnyObject))
    }
    
    func MCSM_runBlock(block: () -> Void){
        block()
    }
    
    func MCSM_performBlock(block: () -> Void){
        if NSThread.currentThread().isEqual(self){
            block()
        }else{
            self.MCSM_performBlock(block, waitUntilDone: false)
        }
    }
    
    func MCSM_performBlock(block: () -> Void, waitUntilDone wait: Bool){
        NSThread.performSelector(Selector("MCSM_runBlock"), onThread: self, withObject: (block as! AnyObject), waitUntilDone: wait)
    }
    
    func MCSM_performBlock(block: () -> Void, afterDelay delay: NSTimeInterval){
        self.performSelector(Selector("MCSM_performBlock"), withObject: (block as! AnyObject), afterDelay: delay)
    }
    
    func applyMutliplication(value: Int, multFunction: Int -> Int) -> Int {
        return multFunction(value)
    }
    
    
}