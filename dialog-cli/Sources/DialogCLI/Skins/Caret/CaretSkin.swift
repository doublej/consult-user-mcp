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

    /// The width a surface of this kind lays itself out at. `DialogManager`
    /// floors the window at `metrics.minWidth` and hands the content that
    /// minus its own inset, so the surface has to agree with the same number
    /// or it will sit in a window slightly wider than itself.
    static func surfaceWidth(for kind: DialogKind) -> CGFloat {
        CaretSkin().metrics(for: kind).minWidth - 16
    }

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

    func textInputView(_ spec: TextInputSpec) -> AnyView {
        wrap(CaretTextInputView(spec: spec))
    }

    func questionsView(_ spec: QuestionsSpec) -> AnyView {
        wrap(CaretQuestionsView(spec: spec))
    }

    func notifyView(_ spec: NotifySpec) -> AnyView {
        wrap(CaretNotifyView(spec: spec))
    }

    func previewView(_ spec: PreviewSpec) -> AnyView {
        wrap(CaretPreviewView(spec: spec))
    }

    private func wrap<V: View>(_ view: V) -> AnyView {
        AnyView(view.environment(\.caretPalette, palette))
    }
}
