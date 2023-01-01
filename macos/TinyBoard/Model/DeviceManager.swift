// Copyright (c) 2022-2023 InSeven Limited
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
import CoreBluetooth
import Foundation

protocol DeviceManagerDelegate: NSObject {

    func deviceManager(_ deviceManager: DeviceManager, shouldConnectToDevice device: Device) -> Bool

}

class DeviceManager: NSObject, ObservableObject {

    enum State {
        case idle
        case scanning
    }

    weak var delegate: DeviceManagerDelegate? = nil

    private var centralManager: CBCentralManager!
    private var timer: Timer? = nil

    @Published var state: State = .idle
    @Published private var _devices: [UUID: Device] = [:]

    var devices: [Device] {
        return _devices
            .values
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] timer in
            self?.removeStaleDevices()
        })
    }

    private func removeStaleDevices() {
        dispatchPrecondition(condition: .onQueue(.main))
        let now = Date()
        let staleDeviceIdentifiers = _devices
            .values
            .filter { device in
                return !device.isConnected && now.timeIntervalSince(device.lastSeen) > 5
            }
            .map { $0.id }
        for identifier in staleDeviceIdentifiers {
            _devices.removeValue(forKey: identifier)
        }
    }

    private func scan() {
        // TODO: Guard the correct state.
        state = .scanning
        centralManager.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    private func cancelScan() {
        centralManager.stopScan()
    }

}

extension DeviceManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
        if _devices[peripheral.identifier] == nil {
            _devices[peripheral.identifier] = Device(centralManager: centralManager, peripheral: peripheral)
        }
        guard let device = _devices[peripheral.identifier] else {
            print("Unable to find device for discovered peripheral \(peripheral.identifier).")
            return
        }
        device.lastSeen = Date()
        if delegate?.deviceManager(self, shouldConnectToDevice: device) ?? false {
            device.connect()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(.main))
        peripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let device = _devices[peripheral.identifier] else {
            print("Unable to find associated device for disconnecting peripheral \(peripheral.identifier).")
            return
        }
        device.didDisconnect()
    }

    func sendEvent(_ event: NSEvent) {
        dispatchPrecondition(condition: .onQueue(.main))
        for device in _devices.values.filter({ $0.isConnected }) {
            device.sendEvent(event)
        }
    }

    func sendKeyDown(_ keyCode: Int) {
        dispatchPrecondition(condition: .onQueue(.main))
        for device in _devices.values.filter({ $0.isConnected }) {
            device.sendKeyDown(keyCode)
        }
    }

    func sendKeyUp(_ keyCode: Int) {
        dispatchPrecondition(condition: .onQueue(.main))
        for device in _devices.values.filter({ $0.isConnected }) {
            device.sendKeyUp(keyCode)
        }
    }
    
}
