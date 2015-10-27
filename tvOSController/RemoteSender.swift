//
//  RemoteSender.swift
//  tvOSController
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation

// Utility methods to wrap the message in a dictionary so we can track messages and replies
extension GCDAsyncSocket {
    func sendMessage(message:[String:AnyObject], withTimeout: NSTimeInterval = -1.0) {
        let data = NSKeyedArchiver.archivedDataWithRootObject([kMessageReplyNotRequired:message])
        self.writeData(data, withTimeout: withTimeout, tag: 0)
    }
    func sendMessageForReply(message:[String:AnyObject], replyKey:Int, withTimeout: NSTimeInterval = -1.0) {
        let data = NSKeyedArchiver.archivedDataWithRootObject([kMessageReplyRequired:message, kMessageReplyID:replyKey])
        self.writeData(data, withTimeout: withTimeout, tag: 0)
    }
    func sendReply(reply:[String:AnyObject], replyKey:Int, withTimeout: NSTimeInterval = -1.0) {
        let data = NSKeyedArchiver.archivedDataWithRootObject([kMessageReply:reply, kMessageReplyID:replyKey])
        self.writeData(data, withTimeout: withTimeout, tag: 0)
    }
}

@objc
public class RemoteSender : NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate {

    internal let coServiceBrowser = NSNetServiceBrowser()
    internal var dictSockets:[String:GCDAsyncSocket] =  [:]
    internal var arrDevices:Set<NSNetService> = []

    internal var replyTagIdentifier:Int = 0
    internal var repliesPending:[Int: (([String : AnyObject]) -> Void)] = [:]

    public var connected:Bool {
        return self.selectedSocket != nil
    }
    
    public func sendMessage(message: [String : AnyObject], replyHandler: (([String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        
        if let selSock = self.selectedSocket {
            
            if let rh = replyHandler {
                let id = ++replyTagIdentifier
                repliesPending[id] = rh
                
                selSock.sendMessageForReply(message, replyKey: id)
            }
            else {
                selSock.sendMessage(message)
            }
            
        }
        else {
            // TODO: Handle error properly
            errorHandler?(NSError(domain: "", code: -1, userInfo: nil))
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
    }
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        //
    }
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        defer { sock.readDataWithTimeout(-1.0, tag: 0) }
        
        if let infoDict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String:AnyObject],
            let reply = infoDict[kMessageReply] as? [String:AnyObject],
            let replyID = infoDict[kMessageReplyID] as? Int  {
                
                if let replyHandler = repliesPending.removeValueForKey(replyID) {
                    replyHandler(reply)
                }
                else {
                    print("Reply received for unknown originator or duplicate reply")
                }
                return
        }
        else if let msg = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? String {
            print("Received Message: \(msg)")
        }
        else if let str = String(data: data, encoding: NSUTF8StringEncoding) where str == "Connected" {
            print("Connected")
            return
        }
        print("Unknown Message: \(String(data: data, encoding: NSUTF8StringEncoding)) - \(data)")
        
    }
    
    public func socketDidCloseReadStream(sock: GCDAsyncSocket!) {
        //
    }
    
    
    
    
    func stopBrowsing() {
        self.coServiceBrowser.stop()
        self.coServiceBrowser.delegate = nil
        print("Browsing Stopped")
    }
    // MARK: NSNetServiceBrowserDelegate
    public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        self.stopBrowsing()
    }
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.stopBrowsing()
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
                if let selSock = self.selectedSocket {
                    let data = "TEST".dataUsingEncoding(NSUTF8StringEncoding)
                    
                    selSock.writeData(data, withTimeout: -1.0, tag: 0)
                }
                else {
                    print("No Connection")
                }
            }
        }
        
    }
    
}

//- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
//{
//    NSLog(@"Will Search");
//}
//- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
//{
//    NSLog(@"Found");
//}




//#include "tvOSController-Swift.h"
//
//#import "GCDAsyncSocket.h"
//
//
//#define ACK_SERVICE_NAME @"_ack._tcp."

