//
//  MessageType.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 07/10/2022.
//

import Foundation

enum MessageType: UInt8 {
    case keyDown = 1
    case keyUp = 2
    case disable = 3
    case enable = 4
}
