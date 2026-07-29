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
