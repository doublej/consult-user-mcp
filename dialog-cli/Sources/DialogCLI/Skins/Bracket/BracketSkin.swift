import SwiftUI

/// **Bracket** — the locked brand system applied to the dialog set.
///
/// Graphite ground, one saturated colour, and the mark's own cursor used as the
/// interface's single focus channel. Sand carries everything the agent said, so
/// "why I am asking" never competes with "what you are choosing".
///
/// `tweak` is deliberately not defined and falls through to the default style,
/// metrics included — §7.1 makes that a supported contract, not an omission.
struct BracketSkin: DialogSkin {
    static let identifier = "bracket"

    let id = BracketSkin.identifier
    let displayName = "Bracket"

    var preferredTheme: ThemeProtocol? { BracketTheme() }

    /// Per-surface minimum widths, shared with each surface's `DialogContainer`
    /// so the two never disagree.
    static func width(for kind: DialogKind) -> CGFloat {
        switch kind {
        case .confirm: return 420
        case .choose: return 470
        case .textInput: return 450
        case .questions: return 490
        case .notify: return 370
        case .preview: return 390
        case .tweak: return ClassicSkin.metrics(for: .tweak).minWidth
        }
    }

    func metrics(for kind: DialogKind) -> SkinWindowMetrics {
        switch kind {
        case .confirm:
            return SkinWindowMetrics(minWidth: Self.width(for: kind), minHeight: 230, maxHeightRatio: 0.85)
        case .choose:
            return SkinWindowMetrics(minWidth: Self.width(for: kind), minHeight: 320, maxHeightRatio: 0.85)
        case .textInput:
            return SkinWindowMetrics(minWidth: Self.width(for: kind), minHeight: 250, maxHeightRatio: 0.85)
        case .questions:
            return SkinWindowMetrics(minWidth: Self.width(for: kind), minHeight: 350, maxHeightRatio: 0.85)
        // §2.2 — the two transient popups cap noticeably lower; they are meant
        // to be glanced at, not read.
        case .notify:
            return SkinWindowMetrics(minWidth: Self.width(for: kind), minHeight: 96, maxHeightRatio: 0.42)
        case .preview:
            return SkinWindowMetrics(minWidth: Self.width(for: kind), minHeight: 104, maxHeightRatio: 0.42)
        case .tweak:
            return ClassicSkin.metrics(for: .tweak)
        }
    }

    func confirmView(_ spec: ConfirmSpec) -> AnyView {
        AnyView(BracketConfirmView(spec: spec))
    }

    func chooseView(_ spec: ChooseSpec) -> AnyView {
        AnyView(BracketChooseView(spec: spec))
    }

    func textInputView(_ spec: TextInputSpec) -> AnyView {
        AnyView(BracketTextInputView(spec: spec))
    }

    func questionsView(_ spec: QuestionsSpec) -> AnyView {
        AnyView(BracketQuestionsView(spec: spec))
    }

    func notifyView(_ spec: NotifySpec) -> AnyView {
        AnyView(BracketNotifyView(spec: spec))
    }

    func previewView(_ spec: PreviewSpec) -> AnyView {
        AnyView(BracketPreviewView(spec: spec))
    }
}
