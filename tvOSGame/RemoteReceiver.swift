//
//  RemoteReceiver.swift
//  tvOSGame
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation


@objc
protocol RemoteReceiverDelegate : NSObjectProtocol {
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String)
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void)
}

@objc
class RemoteReceiver : NSObject, NSNetServiceDelegate, GCDAsyncSocketDelegate, NSNetServiceBrowserDelegate {
    weak var delegate:RemoteReceiverDelegate?

    internal var service:NSNetService!
    internal var socket:GCDAsyncSocket!
    internal var connectedSockets:Set<GCDAsyncSocket> = []
    
    internal let delegateQueue = dispatch_get_main_queue()
    
    override init() {
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        do {
            try self.socket.acceptOnPort(0)
            self.service = NSNetService(domain: "local.", type: SERVICE_NAME, name: "", port: Int32(self.socket.localPort()))
            self.service.delegate = self
            self.service.publish()
        }
        catch let error as NSError {
            fatalError("Unable to create socket. Error \(error) with user info \(error.userInfo).")
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        self.connectedSockets.insert(newSocket)
        newSocket.readDataWithTimeout(-1.0, tag: 0)
       // newSocket.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
        
        let data = "Connected".dataUsingEncoding(NSUTF8StringEncoding)
        newSocket.writeData(data, withTimeout: -1.0, tag: 0)
        
        
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        self.connectedSockets.remove(sock)
        if self.connectedSockets.count == 0 {
            // restart connections
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        defer {
            sock.readDataWithTimeout(-1.0, tag: 0)
        }
        
        if let testString = String(data: data, encoding: NSUTF8StringEncoding),
            let testPosition = testString.rangeOfString("TEST")
            where testPosition.startIndex == testString.startIndex {
            print("PINGED! \(testString)")
        }
        else if let object = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data),
                    let message = object as? [String:AnyObject] {
  
            if let infoDict = message[kMessageReplyNotRequired] as? [String:AnyObject],
                let deviceID = message[kDeviceID] as? String {
                self.delegate?.didReceiveMessage(infoDict, fromDevice: deviceID)
                return
            }
            else if let infoDict = message[kMessageReplyRequired] as? [String:AnyObject],
                let replyID = message[kMessageReplyID] as? Int,
                let deviceID = message[kDeviceID] as? String {
                    
                    self.delegate?.didReceiveMessage(infoDict, fromDevice: deviceID) {
                        (replyMessage) -> Void in
                        let data = NSKeyedArchiver.archivedDataWithRootObject([kMessageReply:replyMessage, kMessageReplyID:replyID])
                        sock.writeData(data, withTimeout: -1.0, tag: 0)
                    }
                    return
                    
            }
            else if let infoDict = message[kMessageReply] as? [String:AnyObject],
                let replyID = message[kMessageReplyID] as? Int,
                let deviceID = message[kDeviceID] as? String {
                    // TODO:
                    print("Reply: \(infoDict) \(replyID) \(deviceID)")
            }                
            else {
                print("Unknown Mesaage: \(message)")
            }
        }
        else {
            print("Unknown Data: \(data)")
            if let testString = String(data: data, encoding: NSUTF8StringEncoding) {
                print("            : \(testString)")
            }
        }
    }
    
}

//internal var arrServices:[NSNetService] = []
//internal var coServiceBrowser:NSNetServiceBrowser!
//internal var dictSockets:[String:AnyObject] = [:]

//    func getSelectedSocket() -> GCDAsyncSocket {
//        if let coServiceName = self.arrServices.first?.name,
//            let rv = self.dictSockets[coServiceName] as? GCDAsyncSocket {
//                return rv
//        }
//        else {
//            fatalError("Could not getSelectedSocket - nil")
//        }
//    }
    
//}

/*
#import "RemoteReceiver.h"
#import "GCDAsyncSocket.h"
#import "tvOSGame-Swift.h"


#define ACK_SERVICE_NAME @"_ack._tcp."



@implementation RemoteReceiver
- (void)netServiceDidPublish:(NSNetService *)service
{
//    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
}
- (void)netService:(NSNetService *)service didNotPublish:(NSDictionary *)errorDict
{
//    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict);
}
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
//    NSLog(@"Write data is done");
}
@end
*/



