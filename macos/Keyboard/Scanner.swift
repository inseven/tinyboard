//
//  Scanner.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 03/10/2022.
//

import CoreBluetooth
import Foundation

// TODO: Consider using a enum with associated values for the current state to make it easier to model safely.

struct SerialConnection {
    let peripheral: CBPeripheral
    let txCharacteristic: CBCharacteristic
    let rxCharaacteristic: CBCharacteristic
}

class Scanner: NSObject, ObservableObject, CBCentralManagerDelegate {

    @Published var peripherals: Set<CBPeripheral> = []

    var centralManager: CBCentralManager!
    var connection: SerialConnection? = nil

    var sortedPeripherals: [CBPeripheral] {
        return peripherals.sorted { $0.safeName.localizedStandardCompare($1.safeName) == .orderedAscending }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func start() {
        centralManager.scanForPeripherals(withServices: [],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")
        print(centralManager.state)

        switch central.state {
        case .poweredOff:
            print("poweredOff")
        case .poweredOn:
            print("poweredOn")
            central.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
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
        peripherals.insert(peripheral)
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        // TODO: Stop scanning.
        print("didConnect")
        peripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }


    func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }

}

extension Scanner: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            // TODO: This seems like an error?
            return
        }
        print("services = \(services)")
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
//        BlePeripheral.connectedService = services[0]
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristics")

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
              let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }

        characteristicASCIIValue = ASCIIstring

        print("Value Recieved: \((characteristicASCIIValue as String))")

        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: "\((characteristicASCIIValue as String))")
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        peripheral.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Function: \(#function),Line: \(#line)")
        print("Message sent")
    }


    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        print("Function: \(#function),Line: \(#line)")
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")

        } else {
            print("Characteristic's value subscribed")
        }

        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }

    // TODO: Move this stuff into the SerialConnection.

    func writeOutgoingValue(data: String){
        guard let connection = connection else {
            return
        }

        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        connection.peripheral.writeValue(valueString!,
                                         for: connection.txCharacteristic,
                                         type: CBCharacteristicWriteType.withResponse)
    }

    func writeCharacteristic(incomingValue: UInt8) {
        guard let connection = connection else {
            return
        }
        var val = incomingValue
        let outgoingData = NSData(bytes: &val, length: MemoryLayout<UInt8>.size)
        connection.peripheral.writeValue(outgoingData as Data,
                                         for: connection.txCharacteristic,
                                         type: CBCharacteristicWriteType.withResponse)
    }

}
