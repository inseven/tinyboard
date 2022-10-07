//
//  ContentView.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 03/10/2022.
//

import CoreBluetooth
import SwiftUI

struct ContentView: View {

    @ObservedObject var bluetoothManager = BluetoothManager()

    var body: some View {

        HStack {
            switch bluetoothManager.state {
            case .idle:
                Text("Idle")
            case .scanning:
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
            case .connecting:
                Text("Connecting...")
            case .connected:
                VStack(spacing: 0) {
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
                    .padding()
                }
            case .disconnecting:
                Text("Disconnecting...")
            }
        }
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
