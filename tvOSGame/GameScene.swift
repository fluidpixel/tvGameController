//
//  GameScene.swift
//  tvOSGame
//
//  Created by Stuart Varrall on 22/10/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, RemoteReceiverDelegate {
    
        let  remote = RemoteReceiver()
    var registeredDevices = [String]()
    var messageCount = 0
    
    var myLabel = SKLabelNode(fontNamed:"HelveticaNeue-UltraLight")
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        myLabel.alpha = 0
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        self.addChild(myLabel)
        
        remote.delegate = self
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in touches {
            let location = touch.locationInNode(self)
            
            let sprite = SKSpriteNode(imageNamed:"Spaceship")
            
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            sprite.position = location
            
            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
            
            sprite.runAction(SKAction.repeatActionForever(action))
            
            self.addChild(sprite)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    func didReceiveMessage(userInfo: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        // TODO:
        didReceiveMessage(userInfo)
        replyHandler(["Reply":0])
        
    }
    func didReceiveMessage(userInfo: [String : AnyObject]) {
        
        let fadeAction = SKAction.sequence([SKAction.fadeAlphaTo(1.0, duration: 0.1), SKAction.waitForDuration(2.0), SKAction.fadeOutWithDuration(1.0)])
        messageCount++
        
        if let deviceID = userInfo["deviceID"]  as? String {
            if registeredDevices.contains(deviceID) {
                let player = registeredDevices.indexOf(deviceID)! + 1
                if let action = userInfo["buttonAction"] as? String {
                        myLabel.text = "\(messageCount) Player: \(player) - Action: \(action)"
                    
                        myLabel.removeAllActions()
                        myLabel.runAction(fadeAction, withKey: "fadeAction")
                }
            } else {
                registeredDevices.append(deviceID)
                myLabel.text = "\(messageCount) Player: \(registeredDevices.count) Registered"
                myLabel.removeAllActions()
                myLabel.runAction(fadeAction, withKey: "fadeAction")
            }
        } else {
            myLabel.text = "\(messageCount) No Dictionary"
            myLabel.removeAllActions()
            myLabel.runAction(fadeAction, withKey: "fadeAction")
        }
        
//        let particlePath = NSBundle.mainBundle().pathForResource("maginPartcle", ofType: "sks")!
//        let particles = NSKeyedUnarchiver.unarchiveObjectWithFile(particlePath) as! SKEmitterNode
//        let effectNode = SKEffectNode()
//        effectNode.addChild(particles)
//        effectNode.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        // Make sure you only add the thruster once to the scene hierarchy or you'll see a crash!
//        self.addChild(effectNode)
        
    }
}
