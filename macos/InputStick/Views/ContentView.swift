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

import CoreBluetooth
import SwiftUI

struct ContentView: View {

    @ObservedObject var bluetoothManager: BluetoothManager

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
        ContentView(bluetoothManager: BluetoothManager())
    }
}
