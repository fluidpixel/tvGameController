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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }

    @IBAction func sendAction(sender: AnyObject) {
        remote.sendInfo(["launch":true])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

