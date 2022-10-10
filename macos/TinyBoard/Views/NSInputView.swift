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

import AppKit

class NSInputView: NSView {

    var connectionManager = ConnectionManager()

    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
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
        connectionManager.sendEvent(event)
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        connectionManager.sendEvent(event)
        super.keyUp(with: event)
    }

}
