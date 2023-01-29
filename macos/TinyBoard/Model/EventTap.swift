// Copyright (c) 2022-2023 InSeven Limited
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

import Foundation
import SwiftUI

// See https://stackoverflow.com/questions/31891002/how-do-you-use-cgeventtapcreate-in-swift
private func eventTapCallback(proxy: CGEventTapProxy,
                      type: CGEventType,
                      event: CGEvent,
                      refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }
    let eventTap = Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue()
    return eventTap.handleEvent(proxy: proxy, type: type, event: event)
}

protocol EventTapDelegate: AnyObject {

    func eventTap(_ eventTap: EventTap, handleEvent event: NSEvent) -> Bool

}

extension CGEventMask {

    static let allEvents = CGEventMask(bitPattern: ~0)

}


class EventTap {

    var eventTap: CFMachPort? = nil

    weak var delegate: EventTapDelegate?

    init() {
    }

    func createEventTapIfNecessary() {
        guard eventTap == nil else {
            return
        }

        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: .allEvents,
                                               callback: eventTapCallback,
                                               userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            print("Failed to create event tap")
            exit(1)
        }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        self.eventTap = eventTap
    }

    func start() {
        createEventTapIfNecessary()
        guard let eventTap = eventTap else {
            print("No event tap to disable")
            return
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        print("disableTap")
        guard let eventTap = eventTap else {
            return
        }
        CGEvent.tapEnable(tap: eventTap, enable: false)
    }

    func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard let nsEvent = NSEvent(cgEvent: event),
              delegate?.eventTap(self, handleEvent: nsEvent) ?? false
        else {
            return Unmanaged.passRetained(event)
        }
        return nil
    }

}
