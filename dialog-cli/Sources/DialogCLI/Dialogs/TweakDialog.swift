import AppKit
import SwiftUI

// MARK: - SwiftUI Tweak Dialog

struct SwiftUITweakDialog: View {
    let bodyText: String
    let parameters: [TweakParameter]
    let fileRewriter: FileRewriter
    let detectedFramework: DetectedFramework?
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

    init(
        bodyText: String,
        parameters: [TweakParameter],
        fileRewriter: FileRewriter,
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

                if let framework = detectedFramework {
                    HStack(spacing: 12) {
                        FrameworkBadge(framework: framework)
                        Spacer()
                        ReplayAnimationsToggle(isOn: $replayAnimations)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

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
            if case .failure = result {
                DispatchQueue.main.async {
                    disabledParams.insert(paramId)
                }
            } else if shouldReplay {
                Self.triggerBrowserReplay()
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

// MARK: - Parameter Card

private struct TweakParameterCard: View {
    let param: TweakParameter
    @Binding var value: Double
    let isDisabled: Bool
    let isFocused: Bool
    let isGrouped: Bool
    let onReset: () -> Void

    @State private var textValue: String = ""

    private var steppedBinding: Binding<Double> {
        Binding(
            get: { value },
            set: { newValue in
                let step = param.effectiveStep
                let snapped = (newValue / step).rounded() * step
                value = min(max(snapped, param.min), param.max)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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

            // Single row: label | slider+ticks | input | unit | reset
            HStack(spacing: 8) {
                Text(param.label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isDisabled ? Theme.Colors.textMuted : Theme.Colors.textSecondary)
                    .lineLimit(1)
                    .frame(width: 100, alignment: .leading)
                    .help("\(param.file):\(param.line)")

                // Slider with tick marks
                VStack(spacing: 2) {
                    Slider(value: steppedBinding, in: param.min...param.max)
                        .disabled(isDisabled)
                        .tint(Theme.Colors.accentBlue)

                    SliderTickMarks(min: param.min, max: param.max, step: param.effectiveStep)
                }

                // Fixed-width value section for alignment
                HStack(spacing: 4) {
                    TextField("", text: $textValue)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(isDisabled ? Theme.Colors.textMuted : Theme.Colors.accentBlue)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 56)
                        .textFieldStyle(.plain)
                        .disabled(isDisabled)
                        .onSubmit { commitTextValue() }

                    Text(param.unit ?? "")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.Colors.textMuted)
                        .frame(width: 24, alignment: .leading)

                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Reset to original value")
                }
                .frame(width: 110, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.Colors.cardBackground.opacity(0.5)))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(borderColor, lineWidth: isFocused ? 1.5 : 0.5)
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
        return Theme.Colors.border.opacity(0.5)
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

// MARK: - Slider Tick Marks

private struct SliderTickMarks: View {
    let min: Double
    let max: Double
    let step: Double

    private let minPixelsPerTick: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let tickCount = tickCount(for: width)

            if tickCount > 1 {
                HStack(spacing: 0) {
                    ForEach(0..<tickCount, id: \.self) { index in
                        if index > 0 { Spacer(minLength: 0) }
                        Rectangle()
                            .fill(Theme.Colors.textMuted.opacity(0.4))
                            .frame(width: 1, height: 4)
                    }
                }
            }
        }
        .frame(height: 4)
    }

    private func tickCount(for width: CGFloat) -> Int {
        let range = max - min
        guard range > 0, step > 0 else { return 0 }

        // Start with natural tick count based on step
        var count = Int((range / step).rounded()) + 1

        // Halve until we meet density constraint
        while count > 1 {
            let spacing = width / CGFloat(count - 1)
            if spacing >= minPixelsPerTick { break }
            count = (count + 1) / 2
        }

        return count
    }
}

// MARK: - Non-Draggable Area

private struct NonDraggableArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NonDraggableNSView {
        NonDraggableNSView()
    }

    func updateNSView(_ nsView: NonDraggableNSView, context: Context) {}
}

private class NonDraggableNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
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
