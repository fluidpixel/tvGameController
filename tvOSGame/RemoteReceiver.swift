//
//  RemoteReceiver.swift
//  tvOSGame
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation

let ERROR_SEND_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -100, userInfo: [NSLocalizedDescriptionKey:"Failed To Send Message"])

let ERROR_REPLY_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -200, userInfo: [NSLocalizedDescriptionKey:"No Message In Reply"])


@objc
protocol RemoteReceiverDelegate : NSObjectProtocol {
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String)
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void)
    
    func deviceDidConnect(device: String, replyHandler: ([String : AnyObject]) -> Void)
}

@objc
public class RemoteReceiver : NSObject, NSNetServiceDelegate, GCDAsyncSocketDelegate, NSNetServiceBrowserDelegate {
    weak var delegate:RemoteReceiverDelegate?

    internal var service:NSNetService!
    internal var socket:GCDAsyncSocket!
    internal var connectedSockets:Set<GCDAsyncSocket> = []
    
    internal var replyGroups:[Int:dispatch_group_t] = [:]
    internal var replyMessages:[Int:(String, [String:AnyObject])] = [:]
    internal var replyIdentifierCounter:Int = 0
    
    internal let delegateQueue = dispatch_get_main_queue()
    
    public func broadcastMessage(message: [String : AnyObject], replyHandler: ((String, [String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        if let rh = replyHandler {
            for sock in connectedSockets {
                let replyID = ++replyIdentifierCounter
                let group = dispatch_group_create()
                dispatch_group_enter(group)
                replyGroups[replyID] = group
                
                dispatch_group_notify(group, dispatch_get_main_queue()) {
                    if let params = self.replyMessages[replyID] {
                        rh(params)
                    }
                    else {
                        errorHandler?(ERROR_REPLY_FAILED)
                    }
                }
                sock.writeData(Message(type: .Broadcast, replyID: replyID, contents: message).data, withTimeout: -1.0, tag: 0)
            }
        }
        else {
            for sock in connectedSockets {
                sock.writeData(Message(type: .Broadcast, contents: message).data, withTimeout: -1.0, tag: 0)
            }
        }        
    }
    
    override init() {
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        
        try! self.socket.acceptOnPort(0)
        self.service = NSNetService(domain: "local.", type: SERVICE_NAME, name: "", port: Int32(self.socket.localPort()))
        self.service.delegate = self
        self.service.publish()

    }
    
    // MARK: GCDAsyncSocketDelegate
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        self.connectedSockets.insert(newSocket)
        newSocket.readDataWithTimeout(-1.0, tag: 0)
        
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        self.connectedSockets.remove(sock)
        if self.connectedSockets.count == 0 {
            // restart connections
        }
    }
    
    
    // curried function to send the user's reply to the sender
    // calling with the first set of arguments returns another function which the user then calls
    private func sendReply(sock: GCDAsyncSocket, _ replyID:Int)(reply:[String:AnyObject]) {
        sock.sendMessageObject(Message(type: .Reply, replyID: replyID, contents: reply))
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        sock.readDataWithTimeout(-1.0, tag: 0)

        if let message = Message(data: data) {
            switch message.type {
            case .Message:
                if let replyID = message.replyID {
                    self.delegate?.didReceiveMessage(message.contents ?? [:], fromDevice: message.senderDeviceID, replyHandler: sendReply(sock, replyID) )
                }
                else {
                    self.delegate?.didReceiveMessage(message.contents ?? [:], fromDevice: message.senderDeviceID)
                }
            case .Reply:
                if let replyID = message.replyID, let group = replyGroups.removeValueForKey(replyID) {
                    
                    if let contents = message.contents {
                        replyMessages[replyID] = (message.senderDeviceID, contents)
                    }
                    
                    dispatch_group_leave(group)
                    
                }
            case .DeviceRegistering:
                if let replyID = message.replyID {
                    self.delegate?.deviceDidConnect(message.senderDeviceID, replyHandler: sendReply(sock, replyID) )
                }
                else {
                    // TODO: Fix this
                   // error - no replying
                    print("Can't reply without ID")
                }
            case .TEST:
                print("PINGED!")
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



