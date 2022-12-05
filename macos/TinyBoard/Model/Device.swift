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
import Combine
import CoreBluetooth
import Foundation

extension NSEvent.EventType {

    var description: String {
        return "TYPE!"
    }

}

enum Mouse: UInt8 {

    case left = 1
    case right = 2
    case middle = 4

}

class Device: NSObject, ObservableObject, Identifiable {

    enum State {
        case disconnected
        case connected(SerialConnection)
    }

    @Published var state: State = .disconnected
    @Published var isEnabled: Bool = true
    @Published var lastSeen = Date()

    private let centralManager: CBCentralManager
    private let peripheral: CBPeripheral
    private var cancellables: Set<AnyCancellable> = []

    var id: UUID {
        return peripheral.identifier
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
        $isEnabled
            .receive(on: DispatchQueue.main)
            .sink { isEnabled in
                switch isEnabled {
                case true:
                    self.enableKeyboardInput()
                case false:
                    self.disableKeyboardInput()
                }
            }
            .store(in: &cancellables)
    }

    func connect() {
        centralManager.connect(peripheral)
    }

    func disconnect() {
        centralManager.cancelPeripheralConnection(peripheral)
        objectWillChange.send()
    }

    func didDisconnect() {
        objectWillChange.send()
    }

    private func writeData(data: Data) {
        guard case .connected(let connection) = state else {
            return
        }
        peripheral.writeValue(data,
                              for: connection.txCharacteristic,
                              type: CBCharacteristicWriteType.withoutResponse)
    }

    func disableKeyboardInput() {
        writeData(data: Data([MessageType.disable.rawValue]))
    }

    func enableKeyboardInput() {
        writeData(data: Data([MessageType.enable.rawValue]))
    }

    var previousFlags: NSEvent.ModifierFlags = []

    func sendEvent(_ event: NSEvent) {

        if event.type == .mouseMoved || event.type == .leftMouseDragged {
            let deltaX = withUnsafeBytes(of: Int8(clamping: Int(ceil(event.deltaX))).bigEndian, Array.init)[0]
            let deltaY = withUnsafeBytes(of: Int8(clamping: Int(ceil(event.deltaY))).bigEndian, Array.init)[0]
            writeData(data: Data([MessageType.mouseMove.rawValue, deltaX, deltaY]))
            return
        } else if event.type == .leftMouseDown {
            writeData(data: Data([MessageType.mousePress.rawValue, Mouse.left.rawValue]))
            return
        } else if event.type == .leftMouseUp {
            writeData(data: Data([MessageType.mouseRelease.rawValue, Mouse.left.rawValue]))
            return
        } else if event.type == .rightMouseDown {
            writeData(data: Data([MessageType.mousePress.rawValue, Mouse.right.rawValue]))
            return
        } else if event.type == .rightMouseUp {
            writeData(data: Data([MessageType.mouseRelease.rawValue, Mouse.right.rawValue]))
            return
        } else if event.type == .scrollWheel {
            print("scroll")
            return
        }

        let keyboardTypes: Set<NSEvent.EventType> = [.keyUp, .keyDown, .flagsChanged]
        guard keyboardTypes.contains(event.type) else {

            // Silently ignore known unsupported types.
            let ignoredTypes: Set<NSEvent.EventType> = [
                .gesture,
                .beginGesture,
                .endGesture,
                .pressure,
                .systemDefined
            ]
            if ignoredTypes.contains(event.type) {
                return
            }

            // Log details about other events.
            print("ignoring unknown event \(event.type)")
            return
        }

        // We don't get regular key down and up events for modifier keys, so we infer these from the
        // CGEventType.flagsChanged event. It feels like there must be a cleaner way to do this, but for
        // the time being, we infer press and release by comparing the previous and current flags and then
        // use the keycode itself to determine the key to press.
        if event.type == .flagsChanged {
            let eventKeyCode = Int(event.keyCode)
            if let keyCode = KeyCodes[eventKeyCode] {
                // Determine whether this is a press or a release.
                if previousFlags.isSubset(of: event.modifierFlags) {
                    writeData(data: Data([MessageType.keyDown.rawValue, keyCode]))
                } else {
                    writeData(data: Data([MessageType.keyUp.rawValue, keyCode]))
                }
            } else {
                print("Failed to look up modifier event with code \(eventKeyCode).")
            }
            previousFlags = event.modifierFlags
            return
        }

        // Determine the message type.
        let messageType: UInt8
        if event.type == .keyDown {
            messageType = MessageType.keyDown.rawValue
        } else {
            messageType = MessageType.keyUp.rawValue
        }

        // The Arduino keyboard handling perfers ASCII input with a few special cases for function keys,
        // modifiers, etc. We therefore lookup those special characters in a mapping table, send them if
        // we find a mapping and, if not, fall back to sending the ASCII code.
        let eventKeyCode = Int(event.keyCode)
        if let keyCode = KeyCodes[eventKeyCode] {
            writeData(data: Data([messageType, keyCode]))
        } else {
            if let character = event.charactersIgnoringModifiers?.first,
               let asciiValue = character.asciiValue {
                writeData(data: Data([messageType, asciiValue]))
            } else {
                print("Failed to find mapping.")
            }
        }

    }

    func sendKeyDown(_ keyCode: Int) {
        guard let deviceKeyCode = KeyCodes[keyCode] else {
            print("Unsupported key code \(keyCode).")
            return
        }
        writeData(data: Data([MessageType.keyDown.rawValue, deviceKeyCode]))
    }

    func sendKeyUp(_ keyCode: Int) {
        guard let deviceKeyCode = KeyCodes[keyCode] else {
            print("Unsupported key code \(keyCode).")
            return
        }
        writeData(data: Data([MessageType.keyUp.rawValue, deviceKeyCode]))
    }

}

extension Device: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let services = peripheral.services else {
            // TODO: This seems like an error?
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let characteristics = service.characteristics else {
            return
        }

        var txCharacteristic: CBCharacteristic? = nil
        var rxCharacteristic: CBCharacteristic? = nil

        for characteristic in characteristics {
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                rxCharacteristic = characteristic
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
            }
        }

        guard let txCharacteristic = txCharacteristic,
              let rxCharacteristic = rxCharacteristic else {
            print("Failed to detect TX and RX characteristics")
            return
        }
        state = .connected(SerialConnection(txCharacteristic: txCharacteristic,
                                            rxCharaacteristic: rxCharacteristic))
        print("Established connection!")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard case .connected(let connection) = state else {
            return
        }
        var characteristicASCIIValue = NSString()
        guard characteristic == connection.rxCharaacteristic,
              let characteristicValue = characteristic.value,
              let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue)  // TODO: ascii?
        else {
            return
        }
        characteristicASCIIValue = ASCIIstring
        print(characteristicASCIIValue as String)
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        peripheral.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        if let error = error {
            print("Failed to write characteristic with error \(error)")
            return
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
        } else {
            print("Characteristic's value subscribed")
        }
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        objectWillChange.send()
    }

}
