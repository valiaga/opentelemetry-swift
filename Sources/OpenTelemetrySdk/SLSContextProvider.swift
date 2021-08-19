//
//  SLSContextProvider.swift
//  OpenTelemetrySdk
//
//  Created by gordon on 2021/8/19.
//

import Foundation
import OpenTelemetryApi
import os.activity

class SLSActivityContextManager: ContextManager {
    static let instance = SLSActivityContextManager()
    let rLock = NSRecursiveLock()
    
    var span: OpenTelemetryApi.Span?
    
    
    func getCurrentContextValue(forKey: String) -> AnyObject? {
        return span
    }
    
    func setCurrentContextValue(forKey: String, value: AnyObject){
        rLock.lock()
        self.span = value as! OpenTelemetryApi.Span?
        rLock.unlock()
    }
    
    func removeContextValue(forKey: String, value: AnyObject) {
        
    }
    
    func getActivityIdent() -> os_activity_id_t {
        return 0
    }
}
