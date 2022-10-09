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

struct ListRowButtonStyle: ButtonStyle {

    @State var hover = false

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(hover ? .selectedMenuItemTextColor : .primary)
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 4.0)
            .fill(hover ? Color.selectedMenuItemColor : .clear))
        .onHover { hover in
            self.hover = hover
        }
    }

}

extension Color {

    static let selectedTextBackgroundColor = Color(nsColor: .selectedTextBackgroundColor)
    static let selectedControlColor = Color(nsColor: .selectedControlColor)
    static let selectedControlTextColor = Color(nsColor: .selectedControlTextColor)
    static let selectedMenuItemColor = Color(nsColor: .selectedMenuItemColor)
    static let selectedMenuItemTextColor = Color(nsColor: .selectedMenuItemTextColor)

}

struct PeripheralRow: View {

    @ObservedObject var peripheral: Peripheral

    var body: some View {
        Button {
            if peripheral.isConnected {
                print("Disconnect...")
                peripheral.disconnect()
            } else {
                print("Connect...")
                peripheral.connect()
            }
        } label: {
            HStack {
                Image(systemName: "mediastick")
                    .foregroundColor(peripheral.isConnected ? .green : .secondary)
                Text(peripheral.name)
                Spacer()
                if peripheral.isConnected {
                    Menu {
                        Button("Enable") {
                            peripheral.enableKeyboardInput()
                        }
                        Button("Disable") {
                            peripheral.disableKeyboardInput()
                        }
                        Divider()
                        Button("Disconnect") {
                            peripheral.disconnect()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(ListRowButtonStyle())
    }

}

struct InputStickMenuBarExtra: Scene {

    @ObservedObject var bluetoothManager: BluetoothManager
    @State var isEnabled = false

    var body: some Scene {
        MenuBarExtra("InputStick", systemImage: "mediastick") {

            VStack {
                Toggle(isOn: $isEnabled) {
                    HStack {
                        Text("Capture Input")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                .toggleStyle(.switch)
                Divider()
                HStack {
                    Text("Devices")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                ForEach(bluetoothManager.peripherals) { peripheral in
                    PeripheralRow(peripheral: peripheral)
                }
                Divider()
                Button("Quit InputStick") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(ListRowButtonStyle())
            }
            .padding()
            
        }
        .menuBarExtraStyle(.window)
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
