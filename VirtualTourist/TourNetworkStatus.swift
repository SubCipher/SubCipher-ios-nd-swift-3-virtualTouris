//
//  TourNetworkStatus.swift
//  VirtualTourist
//
//  Created by knax on 7/18/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import Foundation
import SystemConfiguration


//Referenced from
//https://developer.apple.com/reference/systemconfiguration/scnetworkreachability?language=objc
//https://www.invasivecode.com/weblog/network-reachability-in-swift/?doing_wp_cron=1493790745.3040308952331542968750


let ReachabilityDidChangeNotificationName = "ReachabilityDidChangeNotification"

enum ReachabilityStatus {
    case notReachable
    case reachableViaWiFi
    case reachableViaWWAN
    case reachable
}

class TourNetworkStatus: NSObject {
    
    private var networkReachability: SCNetworkReachability?
    
    init?(hostName: String) {
        networkReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, (hostName as NSString).utf8String!)
        
        super.init()
        if networkReachability == nil {
            return nil
        }
    }
    
    init?(hostAddress: sockaddr_in) {
        var address = hostAddress
        
        guard let defaultRouteReachability = withUnsafePointer(to: &address,{
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }) else {
            return nil
        }
        
        networkReachability = defaultRouteReachability
        
        super.init()
        if networkReachability == nil {
            return nil
        }
    }
    
    static func networkReachabilityForInternetConnection() -> TourNetworkStatus? {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size( ofValue:zeroAddress))
        
        zeroAddress.sin_family = sa_family_t(AF_INET)
        return TourNetworkStatus(hostAddress: zeroAddress)
    }
    
    static func networkReachabilityForLocalWiFi() -> TourNetworkStatus? {
        
        var localWifiAddress = sockaddr_in()
        localWifiAddress.sin_len = UInt8(MemoryLayout.size(ofValue: localWifiAddress))
        
        localWifiAddress.sin_family = sa_family_t(AF_INET)
        //IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0 (0xA9FE0000)
        localWifiAddress.sin_addr.s_addr = 0xA9FE0000
        
        return TourNetworkStatus(hostAddress: localWifiAddress)
    }
    
    private var notifying: Bool = false
    
    func startNotifier() -> Bool {
        guard notifying == false else {
            return false
        }
        
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let reachability = networkReachability, SCNetworkReachabilitySetCallback(reachability, { (target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
           
            //DispatchQueue.main.async {
                //error here (lldb) EXEC_BAD_ACCESS(code=EXC_I386_GPFLT)
                if let currentInfo = info {
                    let infoObject = Unmanaged<AnyObject>.fromOpaque(currentInfo).takeUnretainedValue()
                    
                    if infoObject is TourNetworkStatus {
                        let networkReachability = infoObject as! TourNetworkStatus
                        NotificationCenter.default.post(name: Notification.Name(rawValue: ReachabilityDidChangeNotificationName), object: networkReachability)
                    }
          
                }
            //}
        }, &context) == true else { return false }
        
        guard SCNetworkReachabilityScheduleWithRunLoop(reachability,CFRunLoopGetCurrent(),CFRunLoopMode.defaultMode.rawValue) == true else {return false }
        
        notifying = true
        return notifying
    }
    
    
    private var flags: SCNetworkReachabilityFlags {
        
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        
        if let reachability = networkReachability, withUnsafeMutablePointer(to: &flags, { SCNetworkReachabilityGetFlags(reachability,UnsafeMutablePointer($0)) }) == true {
            return flags
        } else {
            return []
        }
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        if flags.contains(.reachable) == false {
            //The target host is not reachable.
            
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            //WWAN connetions are ok if the calling appliation is using the CFNetwork APIs
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            //if the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi
            return .reachableViaWiFi
        }
        else {
            //if non-specfic connection error to internet
            return .notReachable
        }
    }
    
    var isReachable: Bool {
        switch currentReachabilityStatus {
        case .notReachable:
            return false
        case .reachableViaWiFi, .reachableViaWWAN:
            return true
        case .reachable:
            return true
        }
    }
}
