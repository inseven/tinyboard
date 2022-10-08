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
import Foundation

// Mapping table between macOS keycodes and TinyUSB_Mouse_and_Keyboard codes.
// https://github.com/cyborg5/TinyUSB_Mouse_and_Keyboard/blob/master/TinyUSB_Mouse_and_Keyboard.h
let KeyCodes: [Int: UInt8] = [

    // Layout-independent keycodes.
    kVK_Return: 0xB0,
    kVK_Tab: 0xB3,
    //        kVK_Space:
    kVK_Delete: 0xB2,
    kVK_Escape: 0xB1,
    kVK_Command: 0x83,
    kVK_Shift: 0x81,
    kVK_CapsLock: 0xC1,
    kVK_Option: 0x82,
    kVK_Control: 0x80,
    kVK_RightCommand: 0x87,
    kVK_RightShift: 0x85,
    kVK_RightOption: 0x86,
    kVK_RightControl: 0x84,
    //        kVK_Function:
    //        kVK_VolumeUp:
    //        kVK_VolumeDown:
    //        kVK_Mute:

    kVK_F1: 0xC2,
    kVK_F2: 0xC3,
    kVK_F3: 0xC4,
    kVK_F4: 0xC5,
    kVK_F5: 0xC6,
    kVK_F6: 0xC7,
    kVK_F7: 0xC8,
    kVK_F8: 0xC9,
    kVK_F9: 0xCA,
    kVK_F10: 0xCB,
    kVK_F11: 0xCC,
    kVK_F12: 0xCD,
    kVK_F13: 0xF0,
    kVK_F14: 0xF1,
    kVK_F15: 0xF2,
    kVK_F16: 0xF3,
    kVK_F17: 0xF4,
    kVK_F18: 0xF5,
    kVK_F19: 0xF6,
    kVK_F20: 0xF7,

    //        kVK_Help:
    kVK_PageUp: 0xD3,
    kVK_PageDown: 0xD6,
    kVK_ForwardDelete: 0xD4,
    kVK_Home: 0xD2,
    kVK_End: 0xD5,
    kVK_LeftArrow: 0xD8,
    kVK_RightArrow: 0xD7,
    kVK_DownArrow: 0xD9,
    kVK_UpArrow: 0xDA,
]
