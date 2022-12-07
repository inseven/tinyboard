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

import Interact

struct InputMenuContent: View {

    @Environment(\.closeWindow) private var closeWindow

    @ObservedObject var model: ApplicationModel
    @State var openAtLogin = false

    var body: some View {
        VStack {

            MenuDivider()

            MenuSection {
                Toggle("Open at Login", isOn: $openAtLogin)
            }

            MenuDivider()

            MenuSection {
                Button {
                    closeWindow()
                    model.showAbout()
                } label: {
                    HStack {
                        FixedSpace()
                        Text("About")
                        Spacer()
                    }
                }
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        FixedSpace()
                        Text("Quit")
                        Spacer()
                    }
                }
            }

        }
    }
}


struct InputMenu: Scene {

    @Environment(\.closeWindow) private var closeWindow

    // Observing doens't work here.
    var model: ApplicationModel

    var body: some Scene {
        MenuBarExtra("TinyBoard", systemImage: "mediastick") {
            VStack {
                EnableSwitch(model: model)
                    .padding([.leading, .trailing])

                MenuDivider()

                VStack(spacing: 4) {
                    DeviceList(deviceManager: model.deviceManager)
                        .padding([.leading, .trailing], 6)
                }

                InputMenuContent(model: model)
            }
            .padding([.top, .bottom], 6)
            .environmentObject(model)

        }
        .menuBarExtraStyle(.window)
    }

}
