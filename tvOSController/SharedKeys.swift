//
//  SharedKeys.swift
//  tvOSGame
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation

let SERVICE_NAME = "_probonjore._tcp."

enum RemoteMessageTypes : String {
    case ReplyRequired
    case ReplyNotRequired
    case Reply
}
