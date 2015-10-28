//
//  SharedKeys.swift
//  tvOSGame
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import UIKit

let SERVICE_NAME = "_probonjore._tcp."

let CURRENT_DEVICE_VENDOR_ID:String = UIDevice.currentDevice().identifierForVendor!.UUIDString

enum MessageDirection : CustomStringConvertible {
    case Incoming
    case Outgoing
    
    var description: String {
        switch self {
        case .Incoming: return "Incoming"
        case .Outgoing: return "Outgoing"
        }
    }
}

enum MessageType : String, CustomStringConvertible {
    static let cases = [Message, Broadcast, Reply, DeviceRegistering, TEST]
    
    case Message = "kMessage"
    case Broadcast = "kBroadcast"
    case Reply = "kReply"
    case DeviceRegistering = "kDeviceReg"
    
    case TEST = "TEST"
    
    var description: String {
        switch self {
        case .DeviceRegistering: return "Device Registering"
        case TEST: return "Ping!"
        default: return self.rawValue.substringFromIndex(self.rawValue.startIndex.successor())
        }
    }
}

struct Message {
    let direction:MessageDirection
    let type:MessageType
    let senderDeviceID:String
    let targetDeviceID:String?
    let replyID:Int?
    let contents:[String:AnyObject]?
    
    var isForThisDevice:Bool {
        if let targetDeviceID = self.targetDeviceID {
            return targetDeviceID == CURRENT_DEVICE_VENDOR_ID
        }
        return true
    }
    
    init(type: MessageType, replyID: Int? = nil, contents: [String:AnyObject]? = nil, targetDeviceID: String? = nil) {
        self.type = type
        self.senderDeviceID = CURRENT_DEVICE_VENDOR_ID
        self.targetDeviceID = targetDeviceID
        self.replyID = replyID
        self.contents = contents
        self.direction = .Outgoing
    }
    
    var dictionary:[String:AnyObject] {
        var rv:[String:AnyObject] = ["senderDeviceID":senderDeviceID]
        
        if let contents = self.contents {
            rv[type.rawValue] = contents
        }
        else {
            rv[type.rawValue] = type.rawValue
        }
        
        if let targetDeviceID = self.targetDeviceID {
            rv["targetDeviceID"] = targetDeviceID
        }
        
        if let replyID = self.replyID {
            rv["replyID"] = replyID
        }
        
        return rv
    }
    var data:NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(self.dictionary)
    }
    
    init?(dictionary:[String:AnyObject]) {
        self.direction = .Incoming
        
        self.senderDeviceID = dictionary["senderDeviceID"] as! String
        self.targetDeviceID = dictionary["targetDeviceID"] as? String
        self.replyID = dictionary["replyID"] as? Int
        
        for type in MessageType.cases {
            if let object = dictionary[type.rawValue] {
                self.type = MessageType(rawValue: type.rawValue)!
                if let text = object as? String where text == type.rawValue {
                    self.contents = nil
                    return
                }
                else if let message = object as? [String:AnyObject] {
                    self.contents = message
                    return
                }
                break
            }
        }
        return nil
    }
    
    init?(data:NSData) {
        if let object = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) {
            if let dictionary = object as? [String:AnyObject] {
                self.init(dictionary: dictionary)
                return
            }
        }
        return nil
    }
    
}

extension GCDAsyncSocket {
    func sendMessageObject(message:Message, withTimeout: NSTimeInterval = -1.0) {
        self.writeData(message.data, withTimeout: withTimeout, tag: 0)
    }
}

