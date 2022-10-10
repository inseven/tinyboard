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
import CoreBluetooth
import Foundation

// TODO: Rename to device manager
class ConnectionManager: NSObject, ObservableObject {

    enum State {
        case idle
        case scanning
    }

    private var centralManager: CBCentralManager!

    @Published var state: State = .idle
    @Published private var _peripherals: [UUID: Peripheral] = [:]

    var peripherals: [Peripheral] {
        return _peripherals
            .values
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    private func scan() {
        // TODO: Guard the correct state.
        state = .scanning
        centralManager.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }

    private func cancelScan() {
        centralManager.stopScan()
    }

}

extension ConnectionManager: CBCentralManagerDelegate {

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
        if _peripherals[peripheral.identifier] == nil {
            _peripherals[peripheral.identifier] = Peripheral(centralManager: centralManager, peripheral: peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(.main))
        peripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(.main))
    }

    func sendEvent(_ event: NSEvent) {
        dispatchPrecondition(condition: .onQueue(.main))
        for peripheral in _peripherals.values.filter({ $0.isConnected }) {
            peripheral.sendEvent(event)
        }
    }

    func sendEvent(_ event: CGEvent) {
        dispatchPrecondition(condition: .onQueue(.main))
        for peripheral in _peripherals.values.filter({ $0.isConnected }) {
            peripheral.sendEvent(event)
        }
    }

}
