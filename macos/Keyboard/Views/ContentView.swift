//
//  ContentView.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 03/10/2022.
//

import CoreBluetooth
import SwiftUI

extension Scanner.State {

    var localizedDescription: String {
        switch self {
        case .idle:
            return "Idle"
        case .scanning:
            return "Scanning..."
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        }
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
            .safeAreaInset(edge: .bottom) {
                Text(scanner.state.localizedDescription)
                    .padding()
            }
            VStack {
                InputView(scanner: scanner)
                HStack {
                    Button("Disable Input") {
                        scanner.disableKeyboardInput()
                    }
                    Button("Enable Input") {
                        scanner.enableKeyboardInput();
                    }
                    Button("Disconnect") {
                        scanner.disconnect()
                    }
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
