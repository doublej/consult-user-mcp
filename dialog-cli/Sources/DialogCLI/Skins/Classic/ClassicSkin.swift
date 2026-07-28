import SwiftUI

/// The shipping UI. Pure indirection over the existing `SwiftUI*Dialog`
/// views — activating it changes nothing visually.
struct ClassicSkin: DialogSkin {
    static let identifier = "classic"

    let id = ClassicSkin.identifier
    let displayName = "Classic"

    /// Also the fallback for every skin that has not reskinned a dialog yet,
    /// which is why this is reachable statically.
    static func metrics(for kind: DialogKind) -> SkinWindowMetrics {
        switch kind {
        case .confirm, .choose, .textInput:
            return SkinWindowMetrics()
        case .questions, .tweak:
            return SkinWindowMetrics(minWidth: 460)
        case .notify, .preview:
            return SkinWindowMetrics(minWidth: 360, minHeight: 120, maxHeightRatio: 0.45)
        }
    }

    func metrics(for kind: DialogKind) -> SkinWindowMetrics {
        ClassicSkin.metrics(for: kind)
    }

    func confirmView(_ spec: ConfirmSpec) -> AnyView {
        AnyView(SwiftUIConfirmDialog(
            title: spec.title,
            bodyText: spec.body,
            confirmLabel: spec.confirmLabel,
            cancelLabel: spec.cancelLabel,
            position: spec.position,
            onConfirm: spec.onConfirm,
            onCancel: spec.onCancel,
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ))
    }

    func chooseView(_ spec: ChooseSpec) -> AnyView {
        AnyView(SwiftUIChooseDialog(
            title: spec.title,
            body: spec.body,
            choices: spec.choices,
            descriptions: spec.descriptions,
            allowMultiple: spec.allowMultiple,
            allowOther: spec.allowOther,
            defaultSelection: spec.defaultSelection,
            position: spec.position,
            onComplete: spec.onComplete,
            onCancel: spec.onCancel,
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ))
    }

    func textInputView(_ spec: TextInputSpec) -> AnyView {
        AnyView(SwiftUITextInputDialog(
            title: spec.title,
            bodyText: spec.body,
            isHidden: spec.isHidden,
            defaultValue: spec.defaultValue,
            position: spec.position,
            onSubmit: spec.onSubmit,
            onCancel: spec.onCancel,
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ))
    }

    func questionsView(_ spec: QuestionsSpec) -> AnyView {
        AnyView(SwiftUIWizardDialog(
            title: spec.title,
            bodyText: spec.body,
            questions: spec.questions,
            position: spec.position,
            onComplete: spec.onComplete,
            onCancel: spec.onCancel,
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ))
    }

    func tweakView(_ spec: TweakSpec) -> AnyView {
        AnyView(SwiftUITweakDialog(
            bodyText: spec.body,
            parameters: spec.parameters,
            fileRewriter: spec.fileRewriter,
            position: spec.position,
            onSaveToFile: spec.onSaveToFile,
            onTellAgent: spec.onTellAgent,
            onCancel: spec.onCancel,
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ))
    }

    func notifyView(_ spec: NotifySpec) -> AnyView {
        AnyView(SwiftUINotifyPane(title: spec.title, bodyText: spec.body))
    }

    func previewView(_ spec: PreviewSpec) -> AnyView {
        AnyView(SwiftUIPreviewPane(bodyText: spec.body))
    }
}
