//
//  SerialConnection.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 07/10/2022.
//

import CoreBluetooth
import Foundation

struct SerialConnection {

    let peripheral: CBPeripheral
    let txCharacteristic: CBCharacteristic
    let rxCharaacteristic: CBCharacteristic

    var buffer: String = ""
}
