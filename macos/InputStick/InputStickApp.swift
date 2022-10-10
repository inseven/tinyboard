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

import Combine
import SwiftUI

import Diligence

class ApplicationModel: ObservableObject {

    @Published var isEnabled = false;

    private let eventTap = EventTap()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        $isEnabled
            .receive(on: DispatchQueue.main)
            .sink { isEnabled in
                switch isEnabled {
                case true:
                    self.eventTap.enableTap()
                case false:
                    self.eventTap.disableTap()
                }
            }
            .store(in: &cancellables)
    }

}

@main
struct InputStickApp: App {
    var body: some Scene {

        let bluetoothManager = BluetoothManager()
        let model = ApplicationModel()

        WindowGroup {
            ContentView(model: model, bluetoothManager: bluetoothManager)
        }

        InputMenu(model: model, bluetoothManager: bluetoothManager)

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
