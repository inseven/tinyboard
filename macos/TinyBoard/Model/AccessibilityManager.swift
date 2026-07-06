// Copyright (c) 2022-2025 Jason Morley
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
import ApplicationServices
import Foundation

/// Called on the main.
protocol AccessibilityManagerDelegate: NSObject {

    func accessibilityManagerDidGrantPermissions(_ accessibilityManager: AccessibilityManager)

}

class AccessibilityManager: NSObject {

    weak var delegate: AccessibilityManagerDelegate? = nil

    private(set) var isTrusted = false

    private var timer: Timer? = nil

    override init() {
        super.init()
    }

    func requestPermissions() {
        dispatchPrecondition(condition: .onQueue(.main))

        // Get the current permissions, prompting the user if we don't have them.
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        isTrusted = AXIsProcessTrustedWithOptions(options)

        guard !isTrusted else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.accessibilityManagerDidGrantPermissions(self)
            }
            return
        }

        // Watch for changes to the permissions.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard AXIsProcessTrusted() else { return }
            self.isTrusted = true
            self.timer?.invalidate()
            self.timer = nil
            self.delegate?.accessibilityManagerDidGrantPermissions(self)
        }
    }

}
