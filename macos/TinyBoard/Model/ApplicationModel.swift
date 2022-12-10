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
import Cocoa
import Combine
import CoreGraphics
import ServiceManagement
import SwiftUI

import Diligence

class ApplicationModel: NSObject, ObservableObject {

    @Published var isEnabled = false
    @AppStorage("TrustedDevices") var trustedDevices: Set<UUID> = []

    let deviceManager = DeviceManager()
    private let eventTap = EventTap()
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
                Credit("Pavlos Vinieratos")
                Credit("Sarah Barbour")
                Credit("Tom Sutcliffe")
            }
        } licenses: {
            License("TinyBoard", author: "InSeven Limited", filename: "tinyboard-license")
            License("Interact", author: "InSeven Limited", filename: "interact-license")
        }
    }()

    @MainActor var openAtLogin: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            objectWillChange.send()
            do {
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update service with error \(error).")
            }
        }
    }

    override init() {
        super.init()
        eventTap.delegate = self
        eventTap.start()
        deviceManager.delegate = self

        // Show the HUD on changes.
        $isEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { isEnabled in
                self.showHud(isEnabled: isEnabled)
                if isEnabled {
                    self.hideCursor()
                } else {
                    self.showCursor()
                }
            }
            .store(in: &cancellables)
    }

    func showAbout() {
        dispatchPrecondition(condition: .onQueue(.main))
        NSApplication.shared.activate(ignoringOtherApps: true)
        if !aboutWindow.isVisible {
            aboutWindow.center()
        }
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    func showHud(isEnabled: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        
        let panel = NSPanel(contentViewController: NSHostingController(rootView: HUDView(isEnabled: isEnabled)))
        panel.backgroundColor = .clear
        panel.isMovable = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.styleMask = [.borderless, .hudWindow, .nonactivatingPanel]
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        if let screen = NSScreen.main {
            // Position the HUD in the screen.
            let x = (screen.frame.size.width - panel.frame.size.width) / 2
            panel.setFrame(CGRectMake(x, 140, panel.frame.size.width, panel.frame.size.height), display: true)
        }

        panel.orderFrontRegardless()
    }

    func trustDevice(_ device: Device) {
        dispatchPrecondition(condition: .onQueue(.main))
        trustedDevices.insert(device.id)
    }

    func untrustDevice(_ device: Device) {
        dispatchPrecondition(condition: .onQueue(.main))
        trustedDevices.remove(device.id)
    }

    func showCursor() {
        CGSSetConnectionProperty(_CGSDefaultConnection(),
                                 _CGSDefaultConnection(),
                                 "SetsCursorInBackground" as CFString,
                                 kCFBooleanTrue);
        CGDisplayShowCursor(CGMainDisplayID())
    }

    func hideCursor() {
        CGSSetConnectionProperty(_CGSDefaultConnection(),
                                 _CGSDefaultConnection(),
                                 "SetsCursorInBackground" as CFString,
                                 kCFBooleanTrue);
        CGDisplayHideCursor(CGMainDisplayID())
    }

}

extension ApplicationModel: DeviceManagerDelegate {

    func deviceManager(_ deviceManager: DeviceManager, shouldConnectToDevice device: Device) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        return trustedDevices.contains(where: { $0 == device.id })
    }

}

extension NSEvent {

    var isKeyboardEvent: Bool {
        return type == .keyDown || type == .keyUp
    }

    var deviceIndependentModifiers: NSEvent.ModifierFlags {
        return modifierFlags.intersection(.deviceIndependentFlagsMask)
    }

}

extension ApplicationModel: EventTapDelegate {

    func eventTap(_ eventTap: EventTap, handleEvent event: NSEvent) -> Bool {

        // Check for the enable/disable hotkey.
        if event.isKeyboardEvent,
           event.deviceIndependentModifiers == [.control, .option, .command],
           event.keyCode == kVK_ANSI_K {
            if event.type == .keyDown {
                isEnabled = !isEnabled
            }

            // Ensure we send through the modifier keys that are currently being held by the remote device.
            // It might be more elegant if this were state on device if we could get there but that requires
            // a more complex implementation.
            if isEnabled {
                deviceManager.sendKeyDown(kVK_Command)
                deviceManager.sendKeyDown(kVK_Option)
                deviceManager.sendKeyDown(kVK_Control)
            } else {
                deviceManager.sendKeyUp(kVK_Command)
                deviceManager.sendKeyUp(kVK_Option)
                deviceManager.sendKeyUp(kVK_Control)
            }

            return true
        }

        // Don't capture events unless we're enabled.
        guard isEnabled else {
            return false
        }

        // Send key events.
        deviceManager.sendEvent(event)
        return true
    }

}
