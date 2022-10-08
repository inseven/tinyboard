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

//class Peripheral: NSObject, ObservableObject {
//
//    let peripheral: CBPeripheral
//
//    init(peripheral: CBPeripheral) {
//        self.peripheral = peripheral
//        super.init()
//    }
//
//}

// TODO: Consider using a enum with associated values for the current state to make it easier to model safely.

class BluetoothManager: NSObject, ObservableObject {

    enum State {
        case idle
        case scanning
        case connecting
        case connected
        case disconnecting
    }

    // Mapping table between macOS keycodes and TinyUSB_Mouse_and_Keyboard codes.
    // https://github.com/cyborg5/TinyUSB_Mouse_and_Keyboard/blob/master/TinyUSB_Mouse_and_Keyboard.h
    static let mapping: [Int: UInt8] = [

        // Layout-independent keycodes.
        kVK_Return: 0xB0,
        kVK_Tab: 0xB3,
        //        kVK_Space:
        kVK_Delete: 0xB2,
        kVK_Escape: 0xB1,
        kVK_Command: 0x83,
        kVK_Shift: 0x81,
        kVK_CapsLock: 0xC1,
        kVK_Option: 0x82,
        kVK_Control: 0x80,
        kVK_RightCommand: 0x87,
        kVK_RightShift: 0x85,
        kVK_RightOption: 0x86,
        kVK_RightControl: 0x84,
        //        kVK_Function:
        //        kVK_VolumeUp:
        //        kVK_VolumeDown:
        //        kVK_Mute:

        kVK_F1: 0xC2,
        kVK_F2: 0xC3,
        kVK_F3: 0xC4,
        kVK_F4: 0xC5,
        kVK_F5: 0xC6,
        kVK_F6: 0xC7,
        kVK_F7: 0xC8,
        kVK_F8: 0xC9,
        kVK_F9: 0xCA,
        kVK_F10: 0xCB,
        kVK_F11: 0xCC,
        kVK_F12: 0xCD,
        kVK_F13: 0xF0,
        kVK_F14: 0xF1,
        kVK_F15: 0xF2,
        kVK_F16: 0xF3,
        kVK_F17: 0xF4,
        kVK_F18: 0xF5,
        kVK_F19: 0xF6,
        kVK_F20: 0xF7,

        //        kVK_Help:
        kVK_PageUp: 0xD3,
        kVK_PageDown: 0xD6,
        kVK_ForwardDelete: 0xD4,
        kVK_Home: 0xD2,
        kVK_End: 0xD5,
        kVK_LeftArrow: 0xD8,
        kVK_RightArrow: 0xD7,
        kVK_DownArrow: 0xD9,
        kVK_UpArrow: 0xDA,
    ]

    private var centralManager: CBCentralManager!
    private var connection: SerialConnection? = nil

    var preferredPeripheralIdentifier: UUID? = nil

    @Published var state: State = .idle
    @Published private var _peripherals: Set<CBPeripheral> = []

    var peripherals: [CBPeripheral] {
        return _peripherals
            .sorted { $0.safeName.localizedStandardCompare($1.safeName) == .orderedAscending }
    }

    var disconnectedPeripherals: [CBPeripheral] {
        return _peripherals
            .filter { $0.state != .connected }
            .sorted { $0.safeName.localizedStandardCompare($1.safeName) == .orderedAscending }
    }

    var connectedPeripherals: [CBPeripheral] {
        return _peripherals
            .filter { $0.state == .connected }
            .sorted { $0.safeName.localizedStandardCompare($1.safeName) == .orderedAscending }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func start() {
        centralManager.scanForPeripherals(withServices: [],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    private func scan() {
        // TODO: Guard the correct state.
        state = .scanning
        centralManager.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }

    private func cancelScan() {
        centralManager.stopScan()
    }


    func connect(_ peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard state == .scanning else {
            return
        }
        state = .connecting
        preferredPeripheralIdentifier = peripheral.identifier
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        dispatchPrecondition(condition: .onQueue(.main))
        // TODO: Guard the state too?
        guard let connection = connection else {
            return
        }
        state = .disconnecting
        preferredPeripheralIdentifier = nil
        centralManager.cancelPeripheralConnection(connection.peripheral)
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
            if let keyCode = Self.mapping[Int(event.keyCode)] {
                writeData(data: Data([MessageType.keyDown.rawValue, keyCode, 0]))
            } else if let character = event.characters?.first,
                      let characterCode = character.asciiValue {
                writeData(data: Data([MessageType.keyDown.rawValue, characterCode, 0]))
            }
        case .keyUp:
            if let keyCode = Self.mapping[Int(event.keyCode)] {
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

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")
        print(centralManager.state)

        switch central.state {
        case .poweredOff:
            print("poweredOff")
        case .poweredOn:
            print("poweredOn")
            scan()
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        @unknown default:
            print("unknown (default)")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(.main))
        peripheral.delegate = self
        _peripherals.insert(peripheral)

        // Automatically connect to the preferred peripheral.
        if peripheral.identifier == preferredPeripheralIdentifier {
            connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        // TODO: Stop scanning.
        dispatchPrecondition(condition: .onQueue(.main))
        state = .connected
        cancelScan()
        peripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        connection = nil
        scan()
    }

}

extension BluetoothManager: CBPeripheralDelegate {

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
