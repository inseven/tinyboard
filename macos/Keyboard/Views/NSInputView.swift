//
//  NSInputView.swift
//  Keyboard
//
//  Created by Jason Barrie Morley on 07/10/2022.
//

import AppKit

class NSInputView: NSView {

    var scanner = Scanner()

    init(scanner: Scanner) {
        self.scanner = scanner
        super.init(frame: .zero)
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        self.layer?.backgroundColor = .init(red: 1, green: 0, blue: 0, alpha: 1)
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        self.layer?.backgroundColor = .clear
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        scanner.sendEvent(event)
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        scanner.sendEvent(event)
        super.keyUp(with: event)
    }

}
