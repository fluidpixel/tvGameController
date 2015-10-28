//
//  ViewController.swift
//  tvOSController
//
//  Created by Stuart Varrall on 22/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import UIKit

func printTitled(title:String)(object:Any) {
    print("\(title): \(object)")
}


let colourCycle = [UIColor.redColor(), UIColor.greenColor(), UIColor.yellowColor(), UIColor.blueColor(), UIColor.magentaColor(), UIColor.cyanColor(), UIColor.orangeColor(), UIColor.brownColor(), UIColor.purpleColor()]

class ViewController: UIViewController, TVCSessionDelegate {
    var colour = 0
    let remote = RemoteSender()
    
    @IBOutlet var connectionStatus:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        remote.delegate = self
    }

    @IBAction func sendAction(sender: AnyObject) {
        if let button = sender as? UIButton {
            if let action = button.titleLabel?.text?.lowercaseString {
                
                remote.sendMessage(["buttonAction":action], replyHandler: printTitled("Reply"), errorHandler: printTitled("Error"))
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    // MARK: TVCSessionDelegate
    func didConnect() {
        self.connectionStatus.text = "Connected"
    }
    func didDisconnect() {
        self.connectionStatus.text = "Disconnected"
    }
    func didReceiveBroadcast(message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        self.connectionStatus.backgroundColor = colourCycle[colour++]
        colour%=colourCycle.count
        print("Broadcast Message Received \(message) - reply required")
        replyHandler(["Reply!":colour])
        
     }
    func didReceiveBroadcast(message: [String : AnyObject]) {
        self.connectionStatus.backgroundColor = colourCycle[colour--]
        colour+=colourCycle.count
        colour%=colourCycle.count
        print("Broadcast Message Received \(message) - no reply")
    }
    
    func didReceiveMessage(message: [String : AnyObject]) {
        print("Received Message \(message) - no reply")
    }
    func didReceiveMessage(message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("Received Message \(message) - reply required")
        replyHandler(["Reply!":99])
    }
}



