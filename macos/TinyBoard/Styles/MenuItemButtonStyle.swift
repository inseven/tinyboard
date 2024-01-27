// Copyright (c) 2022-2024 Jason Morley
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

struct MenuItemButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled: Bool
    @State var hover = false

    var foregroundColor: Color {
        guard isEnabled else {
            return .disabledControlTextColor
        }
        return .primary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding([.leading, .trailing], 12)
            .padding([.top, .bottom], 4)
            .background(RoundedRectangle(cornerRadius: 4.0)
                .fill(.primary.opacity(hover && isEnabled ? 0.2 : 0.0)))
            .onHover { hover in
                self.hover = hover
            }
    }

}

extension ButtonStyle where Self == MenuItemButtonStyle {

    static var menuItem: MenuItemButtonStyle {
        return MenuItemButtonStyle()
    }

}
