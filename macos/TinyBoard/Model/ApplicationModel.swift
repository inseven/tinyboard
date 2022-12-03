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

struct HudMaterial: NSViewRepresentable {

    func makeNSView(context: Context) -> NSVisualEffectView {
        let hudMaterial = NSVisualEffectView()
        hudMaterial.blendingMode = .behindWindow
        hudMaterial.isEmphasized = true
        hudMaterial.material = .hudWindow
        hudMaterial.state = NSVisualEffectView.State.active
        return hudMaterial
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {

    }
}

extension View where Self == HudMaterial {

    static var hudMaterial: HudMaterial { HudMaterial() }

}

struct HUDView: View {

    @Environment(\.closeWindow) var closeWindow
    @State var window: NSWindow?

    private struct LayoutMetrics {
        static let cornerRadius = 20.0
        static let size = 200.0
        static let imageFontSize = 72.0
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
                .background(.hudMaterial)
                .cornerRadius(LayoutMetrics.cornerRadius)
                .onDisappear {
                    print("Closing window!")
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
                print("Appeared!")
                showHUD = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation {
                    showHUD = false
                }
            }
        }
    }
}


class ApplicationModel: NSObject, ObservableObject {

    @Published var isEnabled = false;
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

    // TODO: Main actor?
    override init() {
        super.init()
        eventTap.delegate = self
        eventTap.start()
        deviceManager.delegate = self

        $isEnabled
            .receive(on: DispatchQueue.main)
            .sink { isEnabled in
                print("Show HUD \(isEnabled)")
                self.showHud(isEnabled: isEnabled)
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

    // See https://stackoverflow.com/questions/69845268/swiftui-is-it-possible-to-create-macos-huds-like-the-ones-that-comes-up-when-ch.
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

}

extension ApplicationModel: DeviceManagerDelegate {

    func deviceManager(_ deviceManager: DeviceManager, shouldConnectToDevice device: Device) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        return trustedDevices.contains(where: { $0 == device.id })
    }

}

extension ApplicationModel: EventTapDelegate {

    func eventTap(_ eventTap: EventTap, handleEvent event: CGEvent) -> Bool {
        if let nsEvent = NSEvent(cgEvent: event) {
            let deviceIndependentModifiers = nsEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if deviceIndependentModifiers == [.control, .option, .command] && nsEvent.keyCode == kVK_ANSI_K {
                if nsEvent.type == .keyDown {
                    isEnabled = !isEnabled
                }
                return true
            }
        }

        guard isEnabled else {
            return false
        }
        deviceManager.sendEvent(event)
        return true
    }

}
