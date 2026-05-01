import AppKit
import SwiftUI

// MARK: - SwiftUI Tweak Dialog

struct SwiftUITweakDialog: View {
    let bodyText: String
    let parameters: [TweakParameter]
    let fileRewriter: FileRewriter
    let detectedFramework: DetectedFramework?
    let position: DialogPosition
    let onSaveToFile: ([String: Double], Bool) -> Void
    let onTellAgent: ([String: Double], Bool) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String, [String: Double]) -> Void
    let onAskDifferently: (String) -> Void

    @State private var values: [String: Double] = [:]
    @State private var disabledParams: Set<String> = []
    @State private var debounceTimers: [String: DispatchWorkItem] = [:]
    @State private var focusedIndex: Int?
    @State private var replayAnimations: Bool = true
    @State private var showConsole: Bool = false
    @State private var latestEdit: EditEvent?

    init(
        bodyText: String,
        parameters: [TweakParameter],
        fileRewriter: FileRewriter,
        position: DialogPosition,
        onSaveToFile: @escaping ([String: Double], Bool) -> Void,
        onTellAgent: @escaping ([String: Double], Bool) -> Void,
        onCancel: @escaping () -> Void,
        onSnooze: @escaping (Int) -> Void,
        onFeedback: @escaping (String, [String: Double]) -> Void,
        onAskDifferently: @escaping (String) -> Void
    ) {
        self.bodyText = bodyText
        self.parameters = parameters
        self.fileRewriter = fileRewriter
        self.detectedFramework = FrameworkDetector.detect(from: parameters)
        self.position = position
        self.onSaveToFile = onSaveToFile
        self.onTellAgent = onTellAgent
        self.onCancel = onCancel
        self.onSnooze = onSnooze
        self.onFeedback = onFeedback
        self.onAskDifferently = onAskDifferently

        var initial: [String: Double] = [:]
        for p in parameters { initial[p.id] = p.current }
        _values = State(initialValue: initial)
    }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { true },
                onSubmit: { if hasChanges { saveToFile() } else { onCancel() } },
                onCancel: onCancel,
                onArrowLeft: {
                    if KeyboardContext.isEditingText { return false }
                    adjustFocusedValue(by: -1)
                    return focusedIndex != nil
                },
                onArrowRight: {
                    if KeyboardContext.isEditingText { return false }
                    adjustFocusedValue(by: 1)
                    return focusedIndex != nil
                },
                onArrowUp: {
                    if KeyboardContext.isEditingText { return false }
                    if let current = focusedIndex {
                        focusedIndex = max(current - 1, 0)
                    } else {
                        focusedIndex = parameters.count - 1
                    }
                    return true
                },
                onArrowDown: {
                    if KeyboardContext.isEditingText { return false }
                    if let current = focusedIndex {
                        focusedIndex = min(current + 1, parameters.count - 1)
                    } else {
                        focusedIndex = 0
                    }
                    return true
                }
            ),
            currentDialogType: "tweak",
            onAskDifferently: onAskDifferently
        ) { expandedTool in
            VStack(spacing: 0) {
                DialogHeader(
                    icon: "slider.horizontal.3",
                    title: DialogManager.shared.buildTitle(),
                    body: bodyText
                )
                .padding(.bottom, 8)

                tweakToolbarRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                parameterList
                    .clipped()

                DialogToolbar(
                    expandedTool: expandedTool,
                    currentDialogType: "tweak",
                    onSnooze: onSnooze,
                    onFeedback: { feedback in onFeedback(feedback, values) },
                    onAskDifferently: onAskDifferently
                )

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "←→", label: "adjust"),
                        KeyboardHint(key: "⏎", label: hasChanges ? "save" : "cancel"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                    ] + KeyboardHint.toolbarHints,
                    buttons: hasChanges
                        ? [
                            .init("Revert All", action: revertAll),
                            .init("Tell Agent", action: tellAgent),
                            .init("Save to File", isPrimary: true, showReturnHint: true, action: saveToFile),
                        ]
                        : [
                            .init("Cancel", isPrimary: true, showReturnHint: true, action: { onCancel() }),
                        ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(bodyText))
        }
        .background(ConsolePanelBridge(
            showConsole: showConsole,
            position: position,
            editEvent: latestEdit
        ))
    }

    private var tweakToolbarRow: some View {
        HStack(spacing: 8) {
            if let framework = detectedFramework {
                FrameworkBadge(framework: framework)
            }
            if detectedFramework != nil {
                ReplayAnimationsToggle(isOn: $replayAnimations)
            }
            consoleToggleButton
        }
        .frame(maxWidth: .infinity)
    }

    private var consoleToggleButton: some View {
        Button(action: toggleConsole) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 10, weight: .medium))
                Text("Show edits")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(showConsole ? Theme.Colors.accentBlue : Theme.Colors.textMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(showConsole ? Theme.Colors.accentBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .help("Toggle debug console")
    }

    private func toggleConsole() {
        showConsole.toggle()
        if !showConsole { latestEdit = nil }
    }

    private var hasChanges: Bool {
        parameters.contains { p in values[p.id] != p.current }
    }

    private var parameterGroups: [(element: String?, params: [(index: Int, param: TweakParameter)])] {
        var groups: [(element: String?, params: [(index: Int, param: TweakParameter)])] = []
        for (index, param) in parameters.enumerated() {
            if let last = groups.last, last.element == param.element {
                groups[groups.count - 1].params.append((index, param))
            } else {
                groups.append((param.element, [(index, param)]))
            }
        }
        return groups
    }

    private var parameterList: some View {
        ScrollViewReader { proxy in
            AutoSizingScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(parameterGroups.enumerated()), id: \.offset) { _, group in
                        parameterGroupView(group)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .background(NonDraggableArea())
            .onChange(of: focusedIndex) { _, newIndex in
                guard let newIndex else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func parameterGroupView(_ group: (element: String?, params: [(index: Int, param: TweakParameter)])) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Shared element label for the group
            if let element = group.element {
                Text(element)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.Colors.textMuted)
                    .textCase(.uppercase)
                    .padding(.leading, 4)
            }

            // Parameter cards with nested border radius
            VStack(spacing: 4) {
                ForEach(group.params, id: \.param.id) { entry in
                    TweakParameterCard(
                        param: entry.param,
                        value: Binding(
                            get: { values[entry.param.id] ?? entry.param.current },
                            set: { newValue in
                                values[entry.param.id] = newValue
                                debouncedWrite(paramId: entry.param.id, value: newValue)
                            }
                        ),
                        isDisabled: disabledParams.contains(entry.param.id),
                        isFocused: focusedIndex == entry.index,
                        isGrouped: group.params.count > 1,
                        onReset: { resetParam(entry.param.id) }
                    )
                    .onTapGesture { focusedIndex = entry.index }
                    .id(entry.index)
                }
            }
        }
    }

    private func adjustFocusedValue(by direction: Int) {
        guard let index = focusedIndex, index < parameters.count else { return }
        let param = parameters[index]
        guard !disabledParams.contains(param.id) else { return }
        let step = param.effectiveStep
        let current = values[param.id] ?? param.current
        let newValue = min(max(current + step * Double(direction), param.min), param.max)
        values[param.id] = newValue
        debouncedWrite(paramId: param.id, value: newValue)
    }

    private func saveToFile() {
        flushPendingWrites()
        onSaveToFile(values, replayAnimations)
    }

    private func tellAgent() {
        let desiredValues = values
        cancelPendingWrites()
        onTellAgent(desiredValues, replayAnimations)
    }

    private func revertAll() {
        let results = fileRewriter.resetAll()
        for (id, result) in results {
            switch result {
            case .success(let originalValue):
                values[id] = originalValue
                disabledParams.remove(id)
            case .failure:
                disabledParams.insert(id)
            }
        }
        latestEdit = nil
    }

    private func resetParam(_ id: String) {
        debounceTimers[id]?.cancel()
        debounceTimers[id] = nil
        switch fileRewriter.resetParam(id: id) {
        case .success(let originalValue):
            values[id] = originalValue
            disabledParams.remove(id)
        case .failure:
            disabledParams.insert(id)
        }
    }

    private func debouncedWrite(paramId: String, value: Double) {
        debounceTimers[paramId]?.cancel()
        let shouldReplay = replayAnimations
        let work = DispatchWorkItem { [fileRewriter] in
            let result = fileRewriter.applyChange(paramId: paramId, newValue: value)
            switch result {
            case .success(let editEvent):
                DispatchQueue.main.async {
                    latestEdit = editEvent
                }
                if shouldReplay { Self.triggerBrowserReplay() }
            case .failure:
                DispatchQueue.main.async {
                    disabledParams.insert(paramId)
                }
            }
        }
        debounceTimers[paramId] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    private static func triggerBrowserReplay() {
        guard let url = URL(string: "http://localhost:19877/__replay") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 0.5
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    private func flushPendingWrites() {
        for (paramId, work) in debounceTimers {
            work.cancel()
            debounceTimers[paramId] = nil
            guard !disabledParams.contains(paramId) else { continue }
            if let value = values[paramId] {
                let result = fileRewriter.applyChange(paramId: paramId, newValue: value)
                if case .failure = result {
                    disabledParams.insert(paramId)
                }
            }
        }
    }

    private func cancelPendingWrites() {
        for (paramId, work) in debounceTimers {
            work.cancel()
            debounceTimers[paramId] = nil
        }
    }
}

// MARK: - Framework Badge

private struct FrameworkBadge: View {
    let framework: DetectedFramework

    private var icon: String {
        switch framework {
        case .svelte: return "s.circle.fill"
        case .react: return "atom"
        case .vue: return "v.circle.fill"
        case .css: return "paintbrush.fill"
        case .vanilla: return "doc.text.fill"
        }
    }

    private var color: Color {
        switch framework {
        case .svelte: return Color(red: 1.0, green: 0.24, blue: 0.0) // #FF3E00
        case .react: return Color(red: 0.38, green: 0.85, blue: 1.0) // #61DAFB
        case .vue: return Color(red: 0.25, green: 0.78, blue: 0.45) // #42B883
        case .css: return Color(red: 0.0, green: 0.60, blue: 0.86) // #0099DB
        case .vanilla: return Color(red: 0.95, green: 0.85, blue: 0.31) // #F3D950
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)

            Text("Framework detected: \(framework.rawValue)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Replay Animations Toggle

private struct ReplayAnimationsToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 5) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isOn ? Theme.Colors.accentBlue : Theme.Colors.textMuted)

                Text("Replay animations")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
            }
        }
        .buttonStyle(.plain)
        .help("Trigger animation replay after changes (requires browser hook)")
    }
}
