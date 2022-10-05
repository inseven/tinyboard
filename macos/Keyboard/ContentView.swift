//
//  ContentView.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 03/10/2022.
//

import Carbon
import CoreBluetooth
import SwiftUI

class NSInputView: NSView {

    // TODO: These should be unsigned
    // TODO: Should this be an enum?
    struct Event {
        static let null: UInt8 = 0
        static let keyDown: UInt8 = 1
        static let keyUp: UInt8 = 2
    }

    // Mapping table between macOS keycodes and TinyUSB_Mouse_and_Keyboard codes.
    // https://github.com/cyborg5/TinyUSB_Mouse_and_Keyboard/blob/master/TinyUSB_Mouse_and_Keyboard.h
    // TODO: Include the other link.
    static let mapping: [Int: UInt8] = [
        kVK_DownArrow: 0xD9,
        kVK_UpArrow: 0xDA,
        kVK_LeftArrow: 0xD8,
        kVK_RightArrow: 0xD7,
        kVK_Escape: 0xB1,
        kVK_Return: 0xB0,
        kVK_Delete: 0xB2,

//        kVK_Return:
//        kVK_Tab:
//        kVK_Space:
//        kVK_Delete:
//        kVK_Escape:
//        kVK_Command:
//        kVK_Shift:
//        kVK_CapsLock:
//        kVK_Option:
//        kVK_Control:
//        kVK_RightCommand:
//        kVK_RightShift:
//        kVK_RightOption:
//        kVK_RightControl:
//        kVK_Function:
//        kVK_F17:
//        kVK_VolumeUp:
//        kVK_VolumeDown:
//        kVK_Mute:
//        kVK_F18:
//        kVK_F19:
//        kVK_F20:
//        kVK_F5:
//        kVK_F6:
//        kVK_F7:
//        kVK_F3:
//        kVK_F8:
//        kVK_F9:
//        kVK_F11:
//        kVK_F13:
//        kVK_F16:
//        kVK_F14:
//        kVK_F10:
//        kVK_F12:
//        kVK_F15:
//        kVK_Help:
//        kVK_Home:
//        kVK_PageUp:
//        kVK_ForwardDelete:
//        kVK_F4:
//        kVK_End:
//        kVK_F2:
//        kVK_PageDown:
//        kVK_F1:
//        kVK_LeftArrow:
//        kVK_RightArrow:
//        kVK_DownArrow:
//        kVK_UpArrow:
    ]

    var scanner = Scanner()

    init(scanner: Scanner) {
        self.scanner = scanner
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        if let keyCode = Self.mapping[Int(event.keyCode)] {
            scanner.writeCharacteristic(incomingValue: Event.keyDown)
            scanner.writeCharacteristic(incomingValue: keyCode)
            scanner.writeCharacteristic(incomingValue: Event.null)
        } else if let character = event.characters?.first,
                  let characterCode = character.asciiValue {
            scanner.writeCharacteristic(incomingValue: Event.keyDown)
            scanner.writeCharacteristic(incomingValue: characterCode)
            scanner.writeCharacteristic(incomingValue: Event.null)
        }
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if let keyCode = Self.mapping[Int(event.keyCode)] {
            scanner.writeCharacteristic(incomingValue: Event.keyUp)
            scanner.writeCharacteristic(incomingValue: keyCode)
            scanner.writeCharacteristic(incomingValue: Event.null)
        } else if let character = event.characters?.first,
                  let characterCode = character.asciiValue {
            scanner.writeCharacteristic(incomingValue: Event.keyUp)
            scanner.writeCharacteristic(incomingValue: characterCode)
            scanner.writeCharacteristic(incomingValue: Event.null)
        }
        super.keyUp(with: event)
    }

}

extension CBPeripheral: Identifiable {

    public var id: UUID {
        return self.identifier
    }

    var safeName: String {
        return name ?? "Unknown"
    }

}

struct InputView: NSViewRepresentable {

    let scanner: Scanner

    func makeNSView(context: Context) -> some NSInputView {
        return NSInputView(scanner: scanner)
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {

    }

}

struct ContentView: View {

    @ObservedObject var scanner = Scanner()

    var body: some View {
        HStack {
            List {
                ForEach(scanner.sortedPeripherals) { peripheral in
                    HStack {
                        Text(peripheral.name ?? "Unknown")
                        Spacer()
                        Button("Connect") {
                            scanner.connect(peripheral)
                        }
                    }
                }
            }
            VStack {
                InputView(scanner: scanner)
                    .frame(width: 100, height: 100)
                Button("Send!") {
                    scanner.writeOutgoingValue(data: "a")
                }
            }
        }
        .padding()
        .onAppear {
            scanner.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
