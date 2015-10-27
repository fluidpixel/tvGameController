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

class ViewController: UIViewController {

    let remote = RemoteSender()
    let vendorID = UIDevice.currentDevice().identifierForVendor?.UUIDString
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func sendAction(sender: AnyObject) {
        if let button = sender as? UIButton {
            if let action = button.titleLabel?.text?.lowercaseString {
                
                remote.sendMessage(["deviceID": vendorID!, "buttonAction":action], replyHandler: printTitled("Reply"), errorHandler: printTitled("Error"))
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}



