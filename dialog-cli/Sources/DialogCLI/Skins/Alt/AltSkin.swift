import SwiftUI

/// Scaffold for a second, independent dialog UI.
///
/// Selected with `DIALOG_SKIN=alt` or `"skin": "alt"` in settings.json.
/// Layout, spacing and typography are its own; it reuses the behavioural
/// chassis (`DialogContainer`, `FocusableButton`, `FocusableTextField`,
/// `FocusableChoiceCard`, `DialogToolbar`) so keyboard routing, snooze,
/// feedback and the report overlay behave identically to Classic.
///
/// `tweakView` is deliberately not implemented — it falls through to the
/// Classic tweak pane via the `DialogSkin` extension defaults. Implement it
/// here when the tweak pane gets reskinned.
struct AltSkin: DialogSkin {
    static let identifier = "alt"

    let id = AltSkin.identifier
    let displayName = "Alt"

    var preferredTheme: ThemeProtocol? { AltTheme() }

    func metrics(for kind: DialogKind) -> SkinWindowMetrics {
        switch kind {
        case .confirm, .textInput:
            return SkinWindowMetrics(minWidth: 440, minHeight: 260)
        case .choose:
            return SkinWindowMetrics(minWidth: 460, minHeight: 280)
        case .questions:
            return SkinWindowMetrics(minWidth: 480)
        case .tweak:
            return ClassicSkin.metrics(for: .tweak)
        case .notify, .preview:
            return SkinWindowMetrics(minWidth: 390, minHeight: 110, maxHeightRatio: 0.45)
        }
    }

    func confirmView(_ spec: ConfirmSpec) -> AnyView {
        AnyView(AltConfirmView(spec: spec))
    }

    func chooseView(_ spec: ChooseSpec) -> AnyView {
        AnyView(AltChooseView(spec: spec))
    }

    func textInputView(_ spec: TextInputSpec) -> AnyView {
        AnyView(AltTextInputView(spec: spec))
    }

    func questionsView(_ spec: QuestionsSpec) -> AnyView {
        AnyView(AltQuestionsView(spec: spec))
    }

    func notifyView(_ spec: NotifySpec) -> AnyView {
        AnyView(AltNotifyView(spec: spec))
    }

    func previewView(_ spec: PreviewSpec) -> AnyView {
        AnyView(AltPreviewView(spec: spec))
    }
}
