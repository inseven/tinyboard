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

class ApplicationModel: NSObject, ObservableObject {

    @Published var isEnabled = false;
    @AppStorage("TrustedDevices") var trustedDevices: Set<UUID> = []

    let deviceManager = DeviceManager()

    private let eventTap: EventTap
    private var cancellables: Set<AnyCancellable> = []

    private lazy var aboutWindow: NSWindow = {
        return NSWindow(repository: "inseven/tinyboard", copyright: "Copyright © 2022 InSeven Limited") {
            Action("InSeven Limited", url: URL(string: "https://inseven.co.uk")!)
            Action("GitHub", url: URL(string: "https://github.com/inseven/tinyboard")!)
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
            License("TinyBoard", author: "InSeven Limited", filename: "tinyboard-license")
            License("Interact", author: "InSeven Limited", filename: "interact-license")
        }
    }()

    override init() {
        eventTap = EventTap(deviceManager: deviceManager)
        super.init()
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
        deviceManager.delegate = self
    }

    func showAbout() {
        dispatchPrecondition(condition: .onQueue(.main))
        NSApplication.shared.activate(ignoringOtherApps: true)
        if !aboutWindow.isVisible {
            aboutWindow.center()
        }
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    func trustDevice(_ device: Device) {
        dispatchPrecondition(condition: .onQueue(.main))
        trustedDevices.insert(device.id)
    }

    func untrustDevice(_ device: Device) {
        dispatchPrecondition(condition: .onQueue(.main))
        trustedDevices.remove(device.id)
    }

}

extension ApplicationModel: DeviceManagerDelegate {

    func deviceManager(_ deviceManager: DeviceManager, shouldConnectToDevice device: Device) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        return trustedDevices.contains(where: { $0 == device.id })
    }

}
