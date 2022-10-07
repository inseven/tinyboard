//
//  ContentView.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 03/10/2022.
//

import CoreBluetooth
import SwiftUI

extension BluetoothManager.State {

    var localizedDescription: String {
        switch self {
        case .idle:
            return "Idle"
        case .scanning:
            return "Scanning..."
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        }
    }

}

struct ContentView: View {

    @ObservedObject var bluetoothManager = BluetoothManager()

    var body: some View {
        HStack {
            List {
                ForEach(bluetoothManager.peripherals) { peripheral in
                    HStack {
                        Text(peripheral.name ?? "Unknown")
                        Spacer()
                        Button("Connect") {
                            bluetoothManager.connect(peripheral)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(bluetoothManager.state.localizedDescription)
                    .padding()
            }
            VStack {
                InputView(bluetoothManager: bluetoothManager)
                HStack {
                    Button("Disable Input") {
                        bluetoothManager.disableKeyboardInput()
                    }
                    Button("Enable Input") {
                        bluetoothManager.enableKeyboardInput();
                    }
                    Button("Disconnect") {
                        bluetoothManager.disconnect()
                    }
                }
            }
        }
        .padding()
        .onAppear {
            bluetoothManager.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
