import AppKit
import SwiftUI

// MARK: - SwiftUI Tweak Dialog

struct SwiftUITweakDialog: View {
    let bodyText: String
    let parameters: [TweakParameter]
    let fileRewriter: FileRewriter
    let onSaveToFile: ([String: Double]) -> Void
    let onTellAgent: ([String: Double]) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String, [String: Double]) -> Void
    let onAskDifferently: (String) -> Void

    @State private var values: [String: Double] = [:]
    @State private var disabledParams: Set<String> = []
    @State private var debounceTimers: [String: DispatchWorkItem] = [:]
    @State private var focusedIndex: Int?

    init(
        bodyText: String,
        parameters: [TweakParameter],
        fileRewriter: FileRewriter,
        onSaveToFile: @escaping ([String: Double]) -> Void,
        onTellAgent: @escaping ([String: Double]) -> Void,
        onCancel: @escaping () -> Void,
        onSnooze: @escaping (Int) -> Void,
        onFeedback: @escaping (String, [String: Double]) -> Void,
        onAskDifferently: @escaping (String) -> Void
    ) {
        self.bodyText = bodyText
        self.parameters = parameters
        self.fileRewriter = fileRewriter
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
            keyHandler: handleKeyPress,
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
                        KeyboardHint(key: "⏎", label: hasChanges ? "save to file" : "cancel"),
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
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(parameterGroups.enumerated()), id: \.offset) { _, group in
                        parameterGroupView(group)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
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
        let isGrouped = group.params.count > 1
        let hasFocus = focusedIndex.map { f in group.params.contains { $0.index == f } } ?? false
        let hasDisabled = group.params.contains { disabledParams.contains($0.param.id) }

        VStack(alignment: .leading, spacing: 0) {
            if let element = group.element {
                Text(element)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.Colors.textMuted)
                    .textCase(.uppercase)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
            VStack(spacing: 0) {
                ForEach(Array(group.params.enumerated()), id: \.element.param.id) { groupIdx, entry in
                    parameterRow(entry: entry, groupIdx: groupIdx, isGrouped: isGrouped)
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.Colors.cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        hasDisabled ? Theme.Colors.accentRed.opacity(0.5) : hasFocus ? Theme.Colors.accentBlue : Theme.Colors.border,
                        lineWidth: hasFocus ? 2 : 1
                    )
            )
        }
    }

    @ViewBuilder
    private func parameterRow(entry: (index: Int, param: TweakParameter), groupIdx: Int, isGrouped: Bool) -> some View {
        if groupIdx > 0 {
            Divider().background(Theme.Colors.border).padding(.horizontal, 12)
        }
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
            isGrouped: isGrouped,
            onReset: { resetParam(entry.param.id) }
        )
        .onTapGesture { focusedIndex = entry.index }
        .id(entry.index)
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        let isEditingText = NSApp.keyWindow?.firstResponder is NSTextView

        switch keyCode {
        case KeyCode.escape:
            return false
        case KeyCode.returnKey:
            if hasChanges { saveToFile() } else { onCancel() }
            return true
        case KeyCode.downArrow where !isEditingText:
            if let current = focusedIndex {
                focusedIndex = min(current + 1, parameters.count - 1)
            } else {
                focusedIndex = 0
            }
            return true
        case KeyCode.upArrow where !isEditingText:
            if let current = focusedIndex {
                focusedIndex = max(current - 1, 0)
            } else {
                focusedIndex = parameters.count - 1
            }
            return true
        case KeyCode.leftArrow where !isEditingText:
            adjustFocusedValue(by: -1)
            return focusedIndex != nil
        case KeyCode.rightArrow where !isEditingText:
            adjustFocusedValue(by: 1)
            return focusedIndex != nil
        default:
            return false
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
        onSaveToFile(values)
    }

    private func tellAgent() {
        let desiredValues = values
        cancelPendingWrites()
        onTellAgent(desiredValues)
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
        let work = DispatchWorkItem { [fileRewriter] in
            let result = fileRewriter.applyChange(paramId: paramId, newValue: value)
            if case .failure = result {
                DispatchQueue.main.async {
                    disabledParams.insert(paramId)
                }
            }
        }
        debounceTimers[paramId] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
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

// MARK: - Parameter Card

private struct TweakParameterCard: View {
    let param: TweakParameter
    @Binding var value: Double
    let isDisabled: Bool
    let isFocused: Bool
    let isGrouped: Bool
    let onReset: () -> Void

    @State private var textValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top row: label + value + unit + reset
            HStack {
                Text(param.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isDisabled ? Theme.Colors.textMuted : Theme.Colors.textPrimary)
                    .lineLimit(1)
                    .help("\(param.file):\(param.line)")

                Spacer()

                HStack(spacing: 4) {
                    TextField("", text: $textValue)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(isDisabled ? Theme.Colors.textMuted : Theme.Colors.accentBlue)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.plain)
                        .disabled(isDisabled)
                        .onSubmit { commitTextValue() }

                    if let unit = param.unit {
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textMuted)
                    }

                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Reset to original value")
                }
            }

            // Disabled warning
            if isDisabled {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.accentRed)
                    Text("File changed externally")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.accentRed)
                }
            }

            // Slider
            Slider(value: $value, in: param.min...param.max, step: param.effectiveStep)
                .disabled(isDisabled)
                .tint(Theme.Colors.accentBlue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isFocused && isGrouped ? Theme.Colors.cardBackground.opacity(0.5) : Color.clear)
        .background(isGrouped ? Color.clear : Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: isGrouped ? 0 : 10))
        .overlay(
            Group {
                if !isGrouped {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
                }
            }
        )
        .opacity(isDisabled ? 0.7 : 1.0)
        .onAppear { textValue = formatDisplay(value) }
        .onChange(of: value) { _, newValue in
            textValue = formatDisplay(newValue)
        }
    }

    private var borderColor: Color {
        if isDisabled { return Theme.Colors.accentRed.opacity(0.5) }
        if isFocused { return Theme.Colors.accentBlue }
        return Theme.Colors.border
    }

    private func commitTextValue() {
        guard let parsed = Double(textValue) else {
            textValue = formatDisplay(value)
            return
        }
        let clamped = min(max(parsed, param.min), param.max)
        value = clamped
    }

    private func formatDisplay(_ val: Double) -> String {
        if !param.expectedText.contains(".") {
            return String(Int(val.rounded()))
        }
        let parts = param.expectedText.split(separator: ".", maxSplits: 1)
        let decimals = parts.count > 1 ? parts[1].count : 0
        let stepDecimals = param.step.map { decimalPlaces(in: $0) } ?? 0
        return String(format: "%.\(max(decimals, stepDecimals))f", val)
    }

    private func decimalPlaces(in value: Double) -> Int {
        let str = String(value)
        guard let dotIndex = str.firstIndex(of: ".") else { return 0 }
        let afterDot = str[str.index(after: dotIndex)...]
        let trimmed = afterDot.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        return trimmed.count
    }
}
