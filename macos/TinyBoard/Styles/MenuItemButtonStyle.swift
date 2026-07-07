// Copyright (c) 2022-2026 Jason Morley
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

import SwiftUI

import AppKit

struct MenuItemButtonStyle: PrimitiveButtonStyle {

    struct LayoutMetrics {
        static let cornerRadius: CGFloat = 12.0
    }

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.isEnabled) private var isEnabled
    
    @State var hover = false

    var foregroundColor: Color {
        guard isEnabled else {
            return .disabledControlTextColor
        }
        if hover {
            return Color(NSColor.selectedMenuItemTextColor)
        } else {
            return Color(NSColor.controlTextColor)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(foregroundColor)
                .padding([.leading, .trailing], 12)
                .padding([.top, .bottom], 4)
            Spacer()
        }
        .background(RoundedRectangle(cornerRadius: LayoutMetrics.cornerRadius)
            .fill(Color(NSColor.selectedContentBackgroundColor).opacity(hover && isEnabled ? 1.0 : 0.0)))
        .onHover { hover in
            self.hover = hover
        }
        .onTapGesture {
            configuration.trigger()
            dismissWindow()
        }
    }

}

extension PrimitiveButtonStyle where Self == MenuItemButtonStyle {

    static var menuItem: MenuItemButtonStyle {
        return MenuItemButtonStyle()
    }

}
