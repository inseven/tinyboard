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

struct DeviceRow: View {

    @ObservedObject var device: Peripheral

    var body: some View {
        Button {
            guard !device.isConnected else {
                return
            }
            device.connect()
        } label: {
            HStack {
                ZStack {
                    if device.isConnected {
                        Circle()
                            .fill(.tint)
                            .frame(width: 26, height: 26)
                    } else {
                        Circle()
                            .fill(.primary.opacity(0.2))
                            .frame(width: 26, height: 26)
                    }
                    Image(systemName: "mediastick")
                        .foregroundColor(device.isConnected ? .white : .secondary)
                }
                Text(device.name)
                Spacer()
                if device.isConnected {
                    Menu {
                        Button("Enable") {
                            device.enableKeyboardInput()
                        }
                        Button("Disable") {
                            device.disableKeyboardInput()
                        }
                        Divider()
                        Button("Disconnect") {
                            device.disconnect()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(MenuItemButtonStyle())
    }

}