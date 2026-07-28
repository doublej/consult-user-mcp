import SwiftUI

// MARK: - Dialog Kinds

/// Every dialog the CLI can render. Skins key window metrics off this.
enum DialogKind: String, CaseIterable {
    case confirm
    case choose
    case textInput
    case questions
    case tweak
    case notify
    case preview
}

// MARK: - Window Metrics

/// Sizing a skin wants for one dialog kind. `DialogManager` feeds these
/// straight into `createAutoSizedWindow`, so a skin that needs a wider or
/// shorter window says so here instead of editing the manager.
struct SkinWindowMetrics {
    var minWidth: CGFloat
    var minHeight: CGFloat
    var maxHeightRatio: CGFloat

    init(minWidth: CGFloat = 420, minHeight: CGFloat = 300, maxHeightRatio: CGFloat = 0.85) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxHeightRatio = maxHeightRatio
    }
}

// MARK: - Specs
//
// One spec per dialog kind. Each carries the request data plus the callbacks
// `DialogManager` already built — a skin renders and calls back, it never
// touches request decoding, response building, history, or the modal loop.

struct ConfirmSpec {
    let title: String
    let body: String
    let confirmLabel: String
    let cancelLabel: String
    let position: DialogPosition
    let onConfirm: (String?) -> Void
    let onCancel: (String?) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void
}

struct ChooseSpec {
    let title: String
    let body: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let allowOther: Bool
    let defaultSelection: String?
    let position: DialogPosition
    /// `(selectedIndices, otherText, feedback)`
    let onComplete: (Set<Int>, String?, String?) -> Void
    let onCancel: (String?) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void
}

struct TextInputSpec {
    let title: String
    let body: String
    let isHidden: Bool
    let defaultValue: String
    let position: DialogPosition
    /// `(text, feedback)`
    let onSubmit: (String, String?) -> Void
    let onCancel: (String?) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void
}

struct QuestionsSpec {
    let title: String
    let body: String?
    let questions: [QuestionItem]
    let position: DialogPosition
    /// `(answers, otherSelections, otherTexts, perQuestionFeedback, globalFeedback)`
    let onComplete: ([String: QuestionAnswer], [String: Bool], [String: String], [String: String], String?) -> Void
    /// `(globalFeedback, perQuestionFeedback)`
    let onCancel: (String?, [String: String]) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void
}

struct TweakSpec {
    let body: String
    let parameters: [TweakParameter]
    let fileRewriter: FileRewriter
    let position: DialogPosition
    /// `(values, replayAnimations, feedback)`
    let onSaveToFile: ([String: Double], Bool, String?) -> Void
    let onTellAgent: ([String: Double], Bool, String?) -> Void
    let onCancel: (String?) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void
}

struct NotifySpec {
    let title: String
    let body: String
}

struct PreviewSpec {
    let body: String
}

// MARK: - Dialog Skin

/// A complete visual implementation of the dialog set.
///
/// Skins own layout and appearance only. Modal lifecycle, keyboard routing,
/// snooze, feedback and history stay in `DialogManager` / `DialogContainer`,
/// so every skin behaves identically and returns the same response shape.
protocol DialogSkin {
    var id: String { get }
    var displayName: String { get }

    /// Applied by `SkinRegistry` when the skin activates. A `DIALOG_THEME`
    /// override still wins, because it is read after skin resolution.
    var preferredTheme: ThemeProtocol? { get }

    func metrics(for kind: DialogKind) -> SkinWindowMetrics

    func confirmView(_ spec: ConfirmSpec) -> AnyView
    func chooseView(_ spec: ChooseSpec) -> AnyView
    func textInputView(_ spec: TextInputSpec) -> AnyView
    func questionsView(_ spec: QuestionsSpec) -> AnyView
    func tweakView(_ spec: TweakSpec) -> AnyView
    func notifyView(_ spec: NotifySpec) -> AnyView
    func previewView(_ spec: PreviewSpec) -> AnyView
}

/// Every member falls back to the classic UI, so a skin only implements the
/// dialogs it has actually reskinned and still runs end to end.
extension DialogSkin {
    var preferredTheme: ThemeProtocol? { nil }

    func metrics(for kind: DialogKind) -> SkinWindowMetrics { ClassicSkin.metrics(for: kind) }

    func confirmView(_ spec: ConfirmSpec) -> AnyView { ClassicSkin().confirmView(spec) }
    func chooseView(_ spec: ChooseSpec) -> AnyView { ClassicSkin().chooseView(spec) }
    func textInputView(_ spec: TextInputSpec) -> AnyView { ClassicSkin().textInputView(spec) }
    func questionsView(_ spec: QuestionsSpec) -> AnyView { ClassicSkin().questionsView(spec) }
    func tweakView(_ spec: TweakSpec) -> AnyView { ClassicSkin().tweakView(spec) }
    func notifyView(_ spec: NotifySpec) -> AnyView { ClassicSkin().notifyView(spec) }
    func previewView(_ spec: PreviewSpec) -> AnyView { ClassicSkin().previewView(spec) }
}
