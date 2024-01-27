// Copyright (c) 2022-2023 Jason Morley
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

    @EnvironmentObject var model: ApplicationModel
    @ObservedObject var device: Device

    @State var hover = false

    var body: some View {
        Button {
            guard !device.isConnected else {
                return
            }
            model.trustDevice(device)
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
                if device.isConnected && hover {
                    Menu {
                        Toggle("Send Key Events", isOn: $device.isEnabled)
                        Divider()
                        Button("Disconnect") {
                            model.untrustDevice(device)
                            device.disconnect()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onHover { hover in
            self.hover = hover
        }
        .buttonStyle(MenuItemButtonStyle())
    }

}
