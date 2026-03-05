import AppKit
import SwiftUI

// MARK: - Parameter Card

struct TweakParameterCard: View {
    let param: TweakParameter
    @Binding var value: Double
    let isDisabled: Bool
    let isFocused: Bool
    let isGrouped: Bool
    let onReset: () -> Void

    @State private var textValue: String = ""
    @State private var effectiveMin: Double = 0
    @State private var effectiveMax: Double = 0
    @State private var showSettings: Bool = false

    private var steppedBinding: Binding<Double> {
        Binding(
            get: { value },
            set: { newValue in
                let step = param.effectiveStep
                let snapped = (newValue / step).rounded() * step
                value = min(max(snapped, effectiveMin), effectiveMax)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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

            // Single row: label | slider+ticks | input | unit | cogwheel
            HStack(alignment: .top, spacing: 8) {
                Text(param.label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isDisabled ? Theme.Colors.textMuted : Theme.Colors.textSecondary)
                    .frame(minWidth: 60, maxWidth: 120, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .help("\(param.file):\(param.line)")

                // Slider with tick marks (or settings overlay)
                ZStack(alignment: .trailing) {
                    VStack(spacing: 2) {
                        ScrubSlider(
                            value: steppedBinding,
                            range: effectiveMin...effectiveMax,
                            isDisabled: isDisabled
                        )
                        .frame(height: 18)

                        SliderTickMarks(min: effectiveMin, max: effectiveMax, step: param.effectiveStep)
                    }
                    .opacity(showSettings ? 0.3 : 1)

                    if showSettings {
                        SliderSettingsOverlay(
                            effectiveMin: $effectiveMin,
                            effectiveMax: $effectiveMax,
                            originalMin: param.min,
                            originalMax: param.max,
                            onReset: onReset,
                            onDismiss: { withConditionalAnimation { showSettings = false } }
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }

                // Fixed-width value section
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

                    Button(action: toggleSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(showSettings ? Theme.Colors.accentBlue : Theme.Colors.textMuted)
                            .rotationEffect(.degrees(showSettings ? 45 : 0))
                    }
                    .buttonStyle(.plain)
                    .help("Slider settings")
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
        .onAppear {
            effectiveMin = param.min
            effectiveMax = param.max
            textValue = formatDisplay(value)
        }
        .onChange(of: value) { _, newValue in
            textValue = formatDisplay(newValue)
        }
    }

    private var borderColor: Color {
        if isDisabled { return Theme.Colors.accentRed.opacity(0.5) }
        if isFocused { return Theme.Colors.accentBlue }
        return Theme.Colors.border.opacity(0.5)
    }

    private func toggleSettings() {
        withConditionalAnimation { showSettings.toggle() }
    }

    private func commitTextValue() {
        guard let parsed = Double(textValue) else {
            textValue = formatDisplay(value)
            return
        }
        let clamped = min(max(parsed, effectiveMin), effectiveMax)
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

// MARK: - Slider Settings Overlay

private struct SliderSettingsOverlay: View {
    @Binding var effectiveMin: Double
    @Binding var effectiveMax: Double
    let originalMin: Double
    let originalMax: Double
    let onReset: () -> Void
    let onDismiss: () -> Void

    @State private var minText: String = ""
    @State private var maxText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                onReset()
                onDismiss()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            .buttonStyle(.plain)
            .help("Reset to original value")

            rangeField("Min", text: $minText) {
                if let val = Double(minText), val < effectiveMax {
                    effectiveMin = val
                } else {
                    minText = formatNumber(effectiveMin)
                }
            }

            rangeField("Max", text: $maxText) {
                if let val = Double(maxText), val > effectiveMin {
                    effectiveMax = val
                } else {
                    maxText = formatNumber(effectiveMax)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Theme.Colors.border.opacity(0.5), lineWidth: 0.5)
                )
        )
        .onAppear {
            minText = formatNumber(effectiveMin)
            maxText = formatNumber(effectiveMax)
        }
    }

    private func rangeField(_ label: String, text: Binding<String>, onCommit: @escaping () -> Void) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.Colors.textMuted)
            TextField("", text: text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 44)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .onSubmit(onCommit)
        }
    }

    private func formatNumber(_ val: Double) -> String {
        val.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(val)) : String(format: "%.2g", val)
    }
}

// MARK: - Slider Tick Marks

struct SliderTickMarks: View {
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

        var count = Int((range / step).rounded()) + 1

        while count > 1 {
            let spacing = width / CGFloat(count - 1)
            if spacing >= minPixelsPerTick { break }
            count = (count + 1) / 2
        }

        return count
    }
}

// MARK: - Non-Draggable Area

struct NonDraggableArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NonDraggableNSView {
        NonDraggableNSView()
    }

    func updateNSView(_ nsView: NonDraggableNSView, context: Context) {}
}

class NonDraggableNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
}
