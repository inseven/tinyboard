//
//  CBPeripheral.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 05/10/2022.
//

import CoreBluetooth

extension CBPeripheral: Identifiable {

    public var id: UUID {
        return self.identifier
    }

    var safeName: String {
        return name ?? "Unknown"
    }

}
