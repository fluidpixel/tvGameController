//
//  RemoteSender.swift
//  tvOSController
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import UIKit

protocol TVCSessionDelegate : class {
   // TODO:
   // func didReceiveMessage(message: [String : AnyObject], fromDevice: String)
   // func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void)
    
    func didConnect()
    func didDisconnect()
    
    func didReceiveBroadcast(message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void)
}


// Utility methods to wrap the message in a dictionary so we can track messages and replies
extension GCDAsyncSocket {
    @warn_unused_result
    func sendMessageObject(message:Message, withTimeout: NSTimeInterval = -1.0) -> Bool {
        if let data = message.data {
            self.writeData(data, withTimeout: withTimeout, tag: 0)
            return true
        }
        return false
    }
    
    @warn_unused_result
    func sendMessage(message:[String:AnyObject], withTimeout: NSTimeInterval = -1.0) -> Bool {
        return self.sendMessageObject(Message(type: .Message, contents: message), withTimeout: withTimeout)
    }
    
    @warn_unused_result
    func sendMessageForReply(message:[String:AnyObject], replyKey:Int, withTimeout: NSTimeInterval = -1.0) -> Bool  {
        return self.sendMessageObject(Message(type: .Message, replyID: replyKey, contents: message), withTimeout: withTimeout)
    }
    
    @warn_unused_result
    func sendDeviceID(replyKey:Int, withTimeout: NSTimeInterval = -1.0) -> Bool  {
        return self.sendMessageObject(Message(type: .DeviceRegistering, replyID: replyKey), withTimeout: withTimeout)
    }
    
    @warn_unused_result
    func sendReply(reply:[String:AnyObject], replyKey:Int, withTimeout: NSTimeInterval = -1.0) -> Bool  {
        return self.sendMessageObject(Message(type: .Reply, replyID: replyKey, contents: reply), withTimeout: withTimeout)
    }
    
    func ping() {
        assert(self.sendMessageObject(Message(type: .TEST)))
    }
}

let failedToSendError = NSError(domain: "", code: -1, userInfo: nil)
let invalidReplyError = NSError(domain: "", code: -1, userInfo: nil)
@objc
public class RemoteSender : NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate {
    
    weak var delegate:TVCSessionDelegate?

    internal let coServiceBrowser = NSNetServiceBrowser()
    internal var dictSockets:[String:GCDAsyncSocket] =  [:]
    internal var arrDevices:Set<NSNetService> = []

    internal var replyGroups:[Int:dispatch_group_t] = [:]
    internal var replyMessages:[Int:[String:AnyObject]] = [:]
    internal var replyIdentifierCounter:Int = 0

    public var connected:Bool {
        return self.selectedSocket != nil
    }
    
    public func sendMessage(message: [String : AnyObject], replyHandler: (([String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        
        if let selSock = self.selectedSocket {
            if let rh = replyHandler {
                let replyKey = ++replyIdentifierCounter
                let group = dispatch_group_create()
                replyGroups[replyKey] = group
                
                dispatch_group_enter(group)
                
                var error = invalidReplyError
                
                dispatch_group_notify(group, dispatch_get_main_queue()) {
                    if let reply = self.replyMessages.removeValueForKey(replyKey) {
                        rh(reply)
                    }
                    else {
                        errorHandler?(error)
                    }
                }
                
                if !selSock.sendMessageForReply(message, replyKey: replyKey) {
                    error = failedToSendError
                    replyGroups.removeValueForKey(replyKey)
                    dispatch_group_leave(group)
                }
            }
            else {
                if !selSock.sendMessage(message) {
                    errorHandler?(failedToSendError)
                }
            }
        }
        else {
            errorHandler?(failedToSendError)
        }
        
    }
    

    
    var selectedSocket:GCDAsyncSocket? {
        if let coService = self.arrDevices.first?.name {
            return self.dictSockets[coService]
        }
        return nil
    }


    override init() {
        super.init()
        self.coServiceBrowser.delegate = self
        self.coServiceBrowser.searchForServicesOfType(SERVICE_NAME, inDomain: "local.")
    }
    
    func connectWithServer(service:NSNetService) -> Bool {
        if let coSocket = self.dictSockets[service.name] where coSocket.isConnected() {
            return true
        }
        let coSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        
        if let addrs = service.addresses {
            for address in addrs {
                do {
                    try coSocket.connectToAddress(address)
                    self.dictSockets[service.name] = coSocket
                    return true
                }
                catch let error as NSError {
                    print ("Can't connect to \(address)\n\(error)")
                }
            }
        }
        return false

    }
    
    
    // MARK: NSNetServiceBrowserDelegate
    public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        self.coServiceBrowser.stop()
        self.coServiceBrowser.searchForServicesOfType(SERVICE_NAME, inDomain: "local.")
        print("Browsing Stopped")
    }
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.coServiceBrowser.stop()
        self.coServiceBrowser.searchForServicesOfType(SERVICE_NAME, inDomain: "local.")
        print("Browsing Stopped")
    }
    public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        self.arrDevices.remove(service)
    }
    public func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        self.arrDevices.insert(service)
        service.delegate = self
        service.resolveWithTimeout(30.0)
        
        for timer in (1...5).map( { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * NSEC_PER_SEC)) } ) {
            dispatch_after(timer, dispatch_get_main_queue()) {
                self.selectedSocket?.ping()
            }
        }
        
    }
    
    
    // MARK: NSNetServiceDelegate
    public func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.delegate = self
    }
    public func netServiceDidResolveAddress(sender: NSNetService) {
        self.connectWithServer(sender)
    }
    

    // MARK: GCDAsyncSocketDelegate
    public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        sock.readDataWithTimeout(-1.0, tag: 0)
        
        let replyKey = ++replyIdentifierCounter
        let group = dispatch_group_create()
        replyGroups[replyKey] = group
        dispatch_group_enter(group)
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            print("Device Registered")
        }
        _ = sock.sendDeviceID(replyKey)
        
    }
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        delegate?.didDisconnect()
    }
    
    // curried function to send the user's reply to the sender
    // calling with the first set of arguments returns another function which the user then calls
    private func sendReply(sock: GCDAsyncSocket, _ replyID:Int)(reply:[String:AnyObject]) {
        let message = Message(type: .Reply, replyID: replyID, contents: reply)
        sock.writeData(message.data!, withTimeout: -1.0, tag: 0)
    }
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        sock.readDataWithTimeout(-1.0, tag: 0)
        
        if let message = Message(data: data) {
            switch message.type {
            case .Reply:
                if let replyID = message.replyID, let group = replyGroups.removeValueForKey(replyID) {
                    if let reply = message.contents {
                        replyMessages[replyID] = reply
                    }
                    dispatch_group_leave(group)
                }
                else {
                    print("Unable to process reply. Reply received for unknown originator or duplicate reply")
                    // error
                }
            case .Broadcast:
                if let replyID = message.replyID, let contents = message.contents {
                    self.delegate?.didReceiveBroadcast(contents, replyHandler: sendReply(sock, replyID))
                }
                else {
                    print("Unhandled Broadcast Message Received: \(message)")
                    // TODO:
                }
            default:
                print("Unhandled Message Received: \(message.type)")
            }
        }
        else {
            print("Unknown Data: \(data)")
            if let testString = String(data: data, encoding: NSUTF8StringEncoding) {
                print("       UTF8 : \(testString)")
            }
            else if let testString = String(data: data, encoding: NSWindowsCP1250StringEncoding) {
                print("     CP1250 : \(testString)")
            }
        }
        
    }

    
}


/*
internal var replyGroups:[Int:dispatch_group_t] = [:]
internal var replyMessages:[Int:[String:AnyObject]?] = [:]      // NOTE: Possible double optionals (??) here as dictionary can hold null values
internal var replyIdentifierCounter:Int = 0

//internal var replyTagIdentifier:Int = 0
//internal var repliesPending:[Int: (([String : AnyObject]) -> Void)] = [:]
*/

//- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
//{
//    NSLog(@"Will Search");
//}
//- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
//{
//    NSLog(@"Found");
//}
//
//    public func socketDidCloseReadStream(sock: GCDAsyncSocket!) {
//        //
//    }
//




//#include "tvOSController-Swift.h"
//
//#import "GCDAsyncSocket.h"
//
//
//#define ACK_SERVICE_NAME @"_ack._tcp."

