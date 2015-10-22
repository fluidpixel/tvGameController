//
//  ViewController.swift
//  tvOSController
//
//  Created by Stuart Varrall on 22/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let remote = RemoteSender()
    let vendorID = UIDevice.currentDevice().identifierForVendor?.UUIDString
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //on launch register the device with the TV
        remote.sendInfo(["deviceID":vendorID!])
    }

    @IBAction func sendAction(sender: AnyObject) {
        if let button = sender as? UIButton {
            if let action = button.titleLabel?.text?.lowercaseString {
                let dict = ["deviceID": vendorID!, "buttonAction":action]
                remote.sendInfo(dict)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

