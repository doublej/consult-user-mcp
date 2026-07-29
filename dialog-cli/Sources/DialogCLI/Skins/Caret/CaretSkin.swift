import AppKit
import SwiftUI

/// A complete rendering layer. It registers at the skin seam and owns every
/// pixel beneath it: its own container, tools, panes, report flow, prose,
/// scroll region, action, row and field.
///
/// The one exception is `tweak`, which is left to the default style on purpose
/// (§7.3) — its metrics are taken from there too, so it is not sized for a
/// layout it is not using.
struct CaretSkin: DialogSkin {
    static let identifier = "caret"

    let palette: CaretPalette

    init() {
        palette = CaretPalette.resolve()
    }

    var id: String { Self.identifier }
    var displayName: String { "Caret" }

    var preferredTheme: ThemeProtocol? { CaretTheme(palette: palette) }

    func metrics(for kind: DialogKind) -> SkinWindowMetrics {
        let u = CaretStyle.u
        switch kind {
        case .confirm:
            return SkinWindowMetrics(minWidth: u(470), minHeight: u(188), maxHeightRatio: 0.85)
        case .choose:
            return SkinWindowMetrics(minWidth: u(490), minHeight: u(270), maxHeightRatio: 0.85)
        case .textInput:
            return SkinWindowMetrics(minWidth: u(470), minHeight: u(215), maxHeightRatio: 0.85)
        case .questions:
            return SkinWindowMetrics(minWidth: u(510), minHeight: u(300), maxHeightRatio: 0.85)
        case .notify:
            return SkinWindowMetrics(minWidth: u(390), minHeight: u(120), maxHeightRatio: 0.42)
        case .preview:
            return SkinWindowMetrics(minWidth: u(410), minHeight: u(130), maxHeightRatio: 0.42)
        case .tweak:
            return ClassicSkin.metrics(for: .tweak)
        }
    }

    func confirmView(_ spec: ConfirmSpec) -> AnyView {
        wrap(CaretConfirmView(spec: spec))
    }

    func chooseView(_ spec: ChooseSpec) -> AnyView {
        wrap(CaretChooseView(spec: spec))
    }

    private func wrap<V: View>(_ view: V) -> AnyView {
        AnyView(view.environment(\.caretPalette, palette))
    }
}
