//
//  RemoteSender.swift
//  tvOSController
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation

@objc
class RemoteSender : NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate {

    internal var coServiceBrowser:NSNetServiceBrowser?
    internal var mutableData:NSMutableData!
    internal var dictSockets:[String:GCDAsyncSocket] =  [:]
    internal var service:NSNetService!
    internal var socket:GCDAsyncSocket!
    internal var arrDevices:Set<NSNetService> = []
    internal var connected:Bool = false
    
    func sendInfo(infoDict:[NSObject:AnyObject]) {
        let data = NSKeyedArchiver.archivedDataWithRootObject(infoDict)
        self.getSelectedSocket()?.writeData(data, withTimeout: -1.0, tag: 0)
    }
    
    func getSelectedSocket() -> GCDAsyncSocket? {
        if let coService = self.arrDevices.first?.name {
            return self.dictSockets[coService]
        }
        return nil
    }


    override init() {
        super.init()
        self.resetServices()
    }
    
    func resetServices() {
        arrDevices = []
        self.coServiceBrowser = NSNetServiceBrowser()
        self.coServiceBrowser?.delegate = self
        self.coServiceBrowser?.searchForServicesOfType(SERVICE_NAME, inDomain: "local.")
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
    func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.delegate = self
    }
    func netServiceDidResolveAddress(sender: NSNetService) {
        self.connectWithServer(sender)
    }
    

    // MARK: GCDAsyncSocketDelegate
    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        sock.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
    }
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        //
    }
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        sock.readDataWithTimeout(-1.0, tag: 0)
    }
    func socketDidCloseReadStream(sock: GCDAsyncSocket!) {
        //
    }
    
    
    
    
    func stopBrowsing() {
        self.coServiceBrowser?.stop()
        self.coServiceBrowser?.delegate = nil
        self.coServiceBrowser = nil
    }
    // MARK: NSNetServiceBrowserDelegate
    func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        self.stopBrowsing()
    }
    func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.stopBrowsing()
    }
    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        self.arrDevices.remove(service)
    }
    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        self.arrDevices.insert(service)
        service.delegate = self
        service.resolveWithTimeout(30.0)
        
        
        for timer in (1...5).map( { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * NSEC_PER_SEC)) } ) {
            dispatch_after(timer, dispatch_get_main_queue()) {
                let data = "TEST".dataUsingEncoding(NSUTF8StringEncoding)
                self.getSelectedSocket()?.writeData(data, withTimeout: -1.0, tag: 0)
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

