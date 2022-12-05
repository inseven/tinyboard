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

import Carbon
import Combine
import SwiftUI
import Cocoa

import Diligence

struct HUDView: View {

    @Environment(\.closeWindow) var closeWindow
    @State var window: NSWindow?

    private struct LayoutMetrics {
        static let cornerRadius = 20.0
        static let size = 200.0
        static let imageFontSize = 72.0

        static let duration = 1.4
    }

    let isEnabled: Bool

    @State var showHUD: Bool = false

    var body: some View {
        ZStack {
            if showHUD {
                VStack() {
                    Spacer()
                    Image(systemName: isEnabled ? "keyboard.fill" : "keyboard")
                        .font(.system(size: LayoutMetrics.imageFontSize))
                    Spacer()
                    Text(isEnabled ? "Capture On" : "Capture Off")
                        .font(.title)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.hudEffect)
                .cornerRadius(LayoutMetrics.cornerRadius)
                .onDisappear {
                    window?.close()
                }
            }
        }
        .frame(width: LayoutMetrics.size, height: LayoutMetrics.size)
        .hookWindow { window in
            self.window = window
        }
        .onAppear {
            withAnimation {
                showHUD = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + LayoutMetrics.duration) {
                withAnimation {
                    showHUD = false
                }
            }
        }
    }
}
