//
//  InputView.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 05/10/2022.
//

import SwiftUI

struct InputView: NSViewRepresentable {

    let scanner: Scanner

    func makeNSView(context: Context) -> some NSInputView {
        return NSInputView(scanner: scanner)
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {

    }

}
