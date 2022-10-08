// Copyright (c) 2022 InSeven Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import AppKit
import Carbon
import CoreBluetooth
import Foundation

class Peripheral: NSObject, ObservableObject, Identifiable {

    let centralManager: CBCentralManager
    let peripheral: CBPeripheral

    private var connection: SerialConnection? = nil

    var id: UUID {
        return peripheral.identifier
    }

    var state: CBPeripheralState {
        return peripheral.state
    }

    var isConnected: Bool {
        return peripheral.state == .connected
    }

    var name: String {
        return peripheral.name ?? "Unknown"
    }

    init(centralManager: CBCentralManager, peripheral: CBPeripheral) {
        self.centralManager = centralManager
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
    }

    func connect() {
        centralManager.connect(peripheral)
    }

    func disconnect() {
        centralManager.cancelPeripheralConnection(peripheral)
    }

    private func writeData(data: Data) {
        guard let connection = connection else {
            return
        }
        connection.peripheral.writeValue(data,
                                         for: connection.txCharacteristic,
                                         type: CBCharacteristicWriteType.withoutResponse)
    }

    func disableKeyboardInput() {
        writeData(data: Data([MessageType.disable.rawValue, 0]))
    }

    func enableKeyboardInput() {
        writeData(data: Data([MessageType.enable.rawValue, 0]))
    }

    func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .keyDown:
            if let keyCode = KeyCodes[Int(event.keyCode)] {
                writeData(data: Data([MessageType.keyDown.rawValue, keyCode, 0]))
            } else if let character = event.characters?.first,
                      let characterCode = character.asciiValue {
                writeData(data: Data([MessageType.keyDown.rawValue, characterCode, 0]))
            }
        case .keyUp:
            if let keyCode = KeyCodes[Int(event.keyCode)] {
                writeData(data: Data([MessageType.keyUp.rawValue, keyCode, 0]))
            } else if let character = event.characters?.first,
                      let characterCode = character.asciiValue {
                writeData(data: Data([MessageType.keyUp.rawValue, characterCode, 0]))
            }
        default:
            print("Unsupported event.")
        }
    }

}

extension Peripheral: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            // TODO: This seems like an error?
            return
        }
        print("services = \(services)")
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }

        print("Found \(characteristics.count) characteristics.")

        var txCharacteristic: CBCharacteristic? = nil
        var rxCharacteristic: CBCharacteristic? = nil

        for characteristic in characteristics {
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {
                print("found RX")
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("RX Characteristic: \(characteristic.uuid)")
                rxCharacteristic = characteristic
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
                print("found TX")
                print("TX Characteristic: \(characteristic.uuid)")
                txCharacteristic = characteristic
            }
        }

        guard let txCharacteristic = txCharacteristic,
              let rxCharacteristic = rxCharacteristic else {
            print("Failed to detect TX and RX characteristics")
            return
        }

        connection = SerialConnection(peripheral: peripheral,
                                      txCharacteristic: txCharacteristic,
                                      rxCharaacteristic: rxCharacteristic)
        print("Established connection!")
    }

    // TODO: Review code below here.

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        var characteristicASCIIValue = NSString()
        guard characteristic == connection?.rxCharaacteristic,
              let characteristicValue = characteristic.value,
              let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue)  // TODO: ascii?
        else {
            return
        }
        characteristicASCIIValue = ASCIIstring

        print(characteristicASCIIValue as String)
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        peripheral.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
    }


    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")

        } else {
            print("Characteristic's value subscribed")
        }

        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }

}
