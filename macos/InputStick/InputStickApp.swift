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

import SwiftUI

import Diligence

struct InputStickMenuBarExtra: Scene {

    @ObservedObject var bluetoothManager: BluetoothManager

    var body: some Scene {
        MenuBarExtra("InputStick", systemImage: "mediastick") {

            ForEach(bluetoothManager.peripherals) { peripheral in
                Menu {
                    if peripheral.isConnected {
                        Button("Enable Input") {
                            peripheral.enableKeyboardInput();
                        }
                        Button("Disable Input") {
                            peripheral.disableKeyboardInput()
                        }
                        Divider()
                        Button("Disconnect") {
                            peripheral.disconnect()
                        }
                    } else {
                        Button("Connect") {
                            peripheral.connect()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text(peripheral.name)
                    }
                }
            }

            Divider()

            Button("Quit InputStick") {
                NSApplication.shared.terminate(nil)
            }
            
        }
    }

}


@main
struct InputStickApp: App {
    var body: some Scene {

        let bluetoothManager = BluetoothManager()

        WindowGroup {
            ContentView(bluetoothManager: bluetoothManager)
        }

        InputStickMenuBarExtra(bluetoothManager: bluetoothManager)

        About(copyright: "Copyright © 2022 InSeven Limited") {
            Action("InSeven Limited", url: URL(string: "https://inseven.co.uk")!)
            Action("GitHub", url: URL(string: "https://github.com/inseven/inputstick")!)
        } acknowledgements: {
            Acknowledgements("Developers") {
                Credit("Jason Morley", url: URL(string: "https://jbmorley.co.uk"))
            }
            Acknowledgements("Thanks") {
                Credit("Michael Dales")
                Credit("Sarah Barbour")
                Credit("Tom Sutcliffe")
            }
        } licenses: {
            License("InputStick", author: "InSeven Limited", filename: "inputstick-license")
        }

    }
}
