//
//  ContentView.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 03/10/2022.
//

import CoreBluetooth
import SwiftUI

class NSInputView: NSView {

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
        print(event)
        if let characters = event.characters {
            scanner.writeOutgoingValue(data: characters)
        }
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        print(event)
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
