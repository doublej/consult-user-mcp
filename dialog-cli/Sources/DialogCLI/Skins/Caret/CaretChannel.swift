import AppKit
import SwiftUI

/// The one region of a surface that scrolls (§2.3).
///
/// It hugs its content and only starts scrolling once the content passes the
/// cap, which is what lets the surface be measured once and still reflow its
/// height afterwards. Confirm and Text get one too — §10.2 is a defect this
/// layer fixes rather than inherits.
struct CaretChannel<Content: View>: View {
    var cap: CGFloat = CaretStyle.channelCap
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: cap)
    }
}

/// Reveals something without moving anything.
///
/// The window is resized by a service this layer keeps, which measures the
/// content and *then* animates the frame a run-loop turn later. So a layout
/// that animates measures wrong — the measurement catches an interpolated
/// size and the window settles at the wrong height. The layout change
/// therefore lands instantly and correctly, and only opacity is animated, on
/// the window's own curve and with its own lag, so the new element arrives as
/// the frame finishes travelling instead of being pushed outside the clip and
/// sliding back in.
struct CaretReveal: ViewModifier {
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard CaretStyle.animates else { shown = true; return }
                withAnimation(.easeOut(duration: CaretStyle.resizeDuration).delay(CaretStyle.resizeLag)) {
                    shown = true
                }
            }
    }
}

extension View {
    func caretReveal() -> some View { modifier(CaretReveal()) }
}

/// The caller's title. It is a label, not the question — the question is the
/// body — so it is set in the mono face at rail scale, wraps freely and never
/// truncates (§3.3).
struct CaretTitle: View {
    let text: String
    /// A title that is only the surface's own default name says nothing the
    /// badge on the arm has not already said, so it is not drawn twice.
    var suppressing: String? = nil
    @Environment(\.caretPalette) private var palette

    private var visible: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let suppressing else { return true }
        return trimmed.compare(suppressing, options: .caseInsensitive) != .orderedSame
    }

    var body: some View {
        if visible {
            Text(text.uppercased())
                .font(Font(CaretStyle.mono))
                .kerning(CaretStyle.mono.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: CaretStyle.proseMeasure, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}
