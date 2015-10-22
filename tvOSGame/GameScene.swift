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
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
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
    
    func didReceiveMessage(userInfo: [NSObject : AnyObject]!) {
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Button Pressed!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
        let particlePath = NSBundle.mainBundle().pathForResource("maginPartcle", ofType: "sks")!
        let particles = NSKeyedUnarchiver.unarchiveObjectWithFile(particlePath) as! SKEmitterNode
        let effectNode = SKEffectNode()
        effectNode.addChild(particles)
        effectNode.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        // Make sure you only add the thruster once to the scene hierarchy or you'll see a crash!
        self.addChild(effectNode)
        
    }
}
