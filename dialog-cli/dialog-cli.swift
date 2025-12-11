#!/usr/bin/env swift

import AppKit
import AVFoundation
import Foundation
import SwiftUI

// MARK: - Shared Types

enum StringOrStrings: Codable {
    case single(String)
    case multiple([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([String].self) {
            self = .multiple(arr)
        } else if let str = try? container.decode(String.self) {
            self = .single(str)
        } else {
            throw DecodingError.typeMismatch(StringOrStrings.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let str): try container.encode(str)
        case .multiple(let arr): try container.encode(arr)
        }
    }
}

// MARK: - Models

struct ConfirmRequest: Codable {
    let message: String
    let title: String
    let confirmLabel: String
    let cancelLabel: String
    let position: String
}

struct ConfirmResponse: Codable {
    let dialogType: String
    let confirmed: Bool
    let cancelled: Bool
    let dismissed: Bool
    let answer: String?
    let comment: String?
}

struct ChooseRequest: Codable {
    let prompt: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let position: String
}

struct ChoiceResponse: Codable {
    let dialogType: String
    let answer: StringOrStrings?
    let cancelled: Bool
    let dismissed: Bool
    let description: String?
    let descriptions: [String?]?
    let comment: String?
}

struct TextInputRequest: Codable {
    let prompt: String
    let title: String
    let defaultValue: String
    let hidden: Bool
    let position: String
}

struct TextInputResponse: Codable {
    let dialogType: String
    let answer: String?
    let cancelled: Bool
    let dismissed: Bool
    let comment: String?
}

struct NotifyRequest: Codable {
    let message: String
    let title: String
    let subtitle: String?
    let sound: Bool
}

struct NotifyResponse: Codable {
    let dialogType: String
    let success: Bool
}

struct SpeakRequest: Codable {
    let text: String
    let voice: String?
    let rate: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        rate = try container.decode(Int.self, forKey: .rate)
        if container.contains(.voice) {
            voice = try? container.decode(String.self, forKey: .voice)
        } else {
            voice = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case text, voice, rate
    }
}

struct SpeakResponse: Codable {
    let dialogType: String
    let success: Bool
}

// MARK: - Multi-Question Models

struct QuestionOption: Codable {
    let label: String
    let description: String?
}

struct QuestionItem: Codable {
    let id: String
    let question: String
    let options: [QuestionOption]
    let multiSelect: Bool
}

struct QuestionsRequest: Codable {
    let questions: [QuestionItem]
    let mode: String  // "wizard" | "accordion" | "questionnaire"
    let position: String
}

struct QuestionsResponse: Codable {
    let dialogType: String
    let answers: [String: StringOrStrings]
    let cancelled: Bool
    let dismissed: Bool
    let completedCount: Int
}

// MARK: - Modern Theme

struct Theme {
    static let windowBackground = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 0.98)
    static let cardBackground = NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
    static let cardHover = NSColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0)
    static let cardSelected = NSColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1.0)

    static let textPrimary = NSColor.white
    static let textSecondary = NSColor(white: 0.75, alpha: 1.0)
    static let textMuted = NSColor(white: 0.4, alpha: 1.0)

    static let accentBlue = NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0)
    static let accentGreen = NSColor(red: 0.30, green: 0.85, blue: 0.55, alpha: 1.0)
    static let accentRed = NSColor(red: 0.95, green: 0.35, blue: 0.40, alpha: 1.0)

    static let border = NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
    static let inputBackground = NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)

    static let cornerRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let cardRadius: CGFloat = 10

    // SwiftUI Colors
    enum Colors {
        static let windowBackground = Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.98)
        static let cardBackground = Color(red: 0.14, green: 0.14, blue: 0.16)
        static let cardHover = Color(red: 0.18, green: 0.18, blue: 0.22)
        static let cardSelected = Color(red: 0.22, green: 0.22, blue: 0.28)
        static let textPrimary = Color.white
        static let textSecondary = Color(white: 0.75)
        static let textMuted = Color(white: 0.4)
        static let accentBlue = Color(red: 0.35, green: 0.55, blue: 1.0)
        static let accentBlueLight = Color(red: 0.45, green: 0.65, blue: 1.0)
        static let accentBlueDark = Color(red: 0.25, green: 0.45, blue: 0.90)
        static let accentGreen = Color(red: 0.30, green: 0.85, blue: 0.55)
        static let accentRed = Color(red: 0.95, green: 0.35, blue: 0.40)
        static let border = Color(white: 0.35)
        static let inputBackground = Color(red: 0.16, green: 0.16, blue: 0.18)
    }
}

// MARK: - Keyboard Hints View

struct KeyboardHint: Identifiable {
    let id = UUID()
    let key: String
    let label: String
}

struct KeyboardHintsView: View {
    let hints: [KeyboardHint]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(hints) { hint in
                HStack(spacing: 5) {
                    Text(hint.key)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.cardBackground)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Theme.Colors.border.opacity(0.6), lineWidth: 1)
                        )
                    Text(hint.label)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Dialog Header (Composable)

struct DialogHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    init(icon: String, title: String, subtitle: String? = nil, iconColor: Color = Theme.Colors.accentBlue) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .padding(.top, 28)
            .padding(.bottom, 16)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Dialog Footer (Composable)

struct DialogFooter: View {
    let hints: [KeyboardHint]
    let buttons: [DialogButton]

    struct DialogButton: Identifiable {
        let id = UUID()
        let title: String
        let isPrimary: Bool
        let isDestructive: Bool
        let isDisabled: Bool
        let showReturnHint: Bool
        let action: () -> Void

        init(_ title: String, isPrimary: Bool = false, isDestructive: Bool = false, isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isPrimary = isPrimary
            self.isDestructive = isDestructive
            self.isDisabled = isDisabled
            self.showReturnHint = showReturnHint
            self.action = action
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            KeyboardHintsView(hints: hints)
            HStack(spacing: 10) {
                ForEach(buttons) { button in
                    SwiftUIModernButton(
                        title: button.title,
                        isPrimary: button.isPrimary,
                        isDestructive: button.isDestructive,
                        isDisabled: button.isDisabled,
                        showReturnHint: button.showReturnHint,
                        action: button.action
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Dialog Container (Composable)

struct DialogContainer<Content: View>: View {
    let onEscape: (() -> Void)?
    let keyHandler: ((UInt16, NSEvent.ModifierFlags) -> Bool)?
    let content: Content

    @State private var keyboardMonitor: KeyboardNavigationMonitor?

    init(
        onEscape: (() -> Void)? = nil,
        keyHandler: ((UInt16, NSEvent.ModifierFlags) -> Bool)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onEscape = onEscape
        self.keyHandler = keyHandler
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.clear)
            .onAppear { setupKeyboardNavigation() }
            .onDisappear { keyboardMonitor = nil }
    }

    private func setupKeyboardNavigation() {
        keyboardMonitor = KeyboardNavigationMonitor { keyCode, modifiers in
            // Let custom handler try first
            if let handler = keyHandler, handler(keyCode, modifiers) {
                return true
            }
            return false
        }
    }
}

// MARK: - SwiftUI Choice Card

struct SwiftUIChoiceCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isMultiSelect: Bool
    let isFocused: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovered = false

    init(title: String, subtitle: String?, isSelected: Bool, isMultiSelect: Bool = false, isFocused: Bool = false, onTap: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isMultiSelect = isMultiSelect
        self.isFocused = isFocused
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)

                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Show checkbox for multi-select, radio for single-select
                if isMultiSelect {
                    // Checkbox style
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Theme.Colors.accentBlue : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: 2)
                        )
                        .overlay(
                            Group {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                } else {
                    // Radio button style
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .strokeBorder(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: 2)
                        )
                        .overlay(
                            Group {
                                if isSelected {
                                    Circle()
                                        .fill(Theme.Colors.accentBlue)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Theme.Colors.accentBlue.opacity(0.25) : ((isHovered || isFocused) ? Theme.Colors.cardHover : Theme.Colors.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isFocused ? Theme.Colors.accentBlue.opacity(0.8) : (isSelected ? Theme.Colors.accentBlue : Theme.Colors.border),
                        lineWidth: (isSelected || isFocused) ? 2 : 1
                    )
            )
            .overlay(
                // Focus ring glow effect
                Group {
                    if isFocused && !isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.accentBlue.opacity(0.4), lineWidth: 3)
                            .padding(-2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .onHover { hovering in
            if reduceMotion {
                isHovered = hovering
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .accessibilityLabel(Text(title))
        .accessibilityHint(subtitle.map { Text($0) } ?? Text(""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - SwiftUI Modern Button

struct SwiftUIModernButton: View {
    let title: String
    let isPrimary: Bool
    let isDestructive: Bool
    let isDisabled: Bool
    let showReturnHint: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovered = false
    @State private var isPressed = false

    init(title: String, isPrimary: Bool = false, isDestructive: Bool = false, isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.showReturnHint = showReturnHint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: isPrimary ? .semibold : .medium))
                    .foregroundColor(buttonTextColor)
                if showReturnHint && isPrimary && !isDisabled {
                    Image(systemName: "return")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(buttonTextColor.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isPrimary ? Color.clear : Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled)
        .onHover { hovering in
            guard !isDisabled else { return }
            if reduceMotion {
                isHovered = hovering
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isPrimary ? .isButton : [.isButton])
    }

    private var buttonFill: AnyShapeStyle {
        if isDisabled {
            return AnyShapeStyle(Theme.Colors.cardBackground.opacity(0.5))
        } else if isPrimary {
            return AnyShapeStyle(LinearGradient(
                colors: isHovered
                    ? [Theme.Colors.accentBlue, Theme.Colors.accentBlueDark]
                    : [Theme.Colors.accentBlueLight, Theme.Colors.accentBlue],
                startPoint: .top,
                endPoint: .bottom
            ))
        } else if isDestructive {
            return AnyShapeStyle(isHovered ? Theme.Colors.accentRed.opacity(0.3) : Theme.Colors.accentRed.opacity(0.2))
        } else {
            return AnyShapeStyle(isHovered ? Theme.Colors.cardHover : Theme.Colors.cardBackground)
        }
    }

    private var buttonTextColor: Color {
        if isDisabled {
            return Theme.Colors.textMuted
        } else if isPrimary {
            return .white
        } else if isDestructive {
            return Theme.Colors.accentRed
        } else {
            return Theme.Colors.textPrimary
        }
    }
}

// MARK: - Button Press Style

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - SwiftUI Confirm Dialog

struct SwiftUIConfirmDialog: View {
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        DialogContainer(keyHandler: { keyCode, _ in
            if keyCode == 36 { // Enter/Return - confirm
                onConfirm()
                return true
            }
            return false
        }) {
            VStack(spacing: 0) {
                DialogHeader(icon: "questionmark", title: title, subtitle: message)
                    .padding(.bottom, 12)

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "⏎", label: "confirm"),
                        KeyboardHint(key: "Esc", label: "cancel")
                    ],
                    buttons: [
                        .init(cancelLabel, action: onCancel),
                        .init(confirmLabel, isPrimary: true, showReturnHint: true, action: onConfirm)
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title). \(message)"))
        }
    }
}

// MARK: - Modern Styled Text Field (AppKit)

class StyledTextField: NSView {
    let textField: NSTextField
    private let isSecure: Bool
    private var isFocused = false
    private var focusAnimationProgress: CGFloat = 0.0
    private var animationDisplayLink: CVDisplayLink?

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    init(isSecure: Bool, defaultValue: String) {
        self.isSecure = isSecure
        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }
        super.init(frame: .zero)

        textField.stringValue = defaultValue
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.textColor = Theme.textPrimary
        textField.delegate = self

        addSubview(textField)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        textField.frame = bounds.insetBy(dx: 14, dy: 0)
        textField.frame.origin.y = (bounds.height - 22) / 2
        textField.frame.size.height = 22
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(textField)
    }

    private func animateFocusChange(to focused: Bool) {
        let targetProgress: CGFloat = focused ? 1.0 : 0.0
        let duration: TimeInterval = 0.12
        let startProgress = focusAnimationProgress
        let startTime = CACurrentMediaTime()

        // Use NSTimer for simple animation
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            let elapsed = CACurrentMediaTime() - startTime
            let t = min(elapsed / duration, 1.0)
            // Ease-out curve
            let easedT = 1.0 - pow(1.0 - t, 3)

            self.focusAnimationProgress = startProgress + (targetProgress - startProgress) * CGFloat(easedT)
            self.needsDisplay = true

            if t >= 1.0 {
                timer.invalidate()
                self.focusAnimationProgress = targetProgress
                self.needsDisplay = true
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)

        // Animated glow when focused
        if focusAnimationProgress > 0 {
            let glowRect = bounds.insetBy(dx: -2, dy: -2)
            let glowPath = NSBezierPath(roundedRect: glowRect, xRadius: 12, yRadius: 12)
            Theme.accentBlue.withAlphaComponent(0.3 * focusAnimationProgress).setFill()
            glowPath.fill()
        }

        Theme.inputBackground.setFill()
        path.fill()

        // Interpolate border color and width
        let unfocusedColor = Theme.border
        let focusedColor = Theme.accentBlue
        let borderColor = NSColor(
            red: unfocusedColor.redComponent + (focusedColor.redComponent - unfocusedColor.redComponent) * focusAnimationProgress,
            green: unfocusedColor.greenComponent + (focusedColor.greenComponent - unfocusedColor.greenComponent) * focusAnimationProgress,
            blue: unfocusedColor.blueComponent + (focusedColor.blueComponent - unfocusedColor.blueComponent) * focusAnimationProgress,
            alpha: 1.0
        )
        borderColor.setStroke()
        path.lineWidth = 1.0 + 1.5 * focusAnimationProgress
        path.stroke()
    }
}

extension StyledTextField: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        isFocused = true
        animateFocusChange(to: true)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        isFocused = false
        animateFocusChange(to: false)
    }
}

// MARK: - Keyboard Navigation Monitor

class KeyboardNavigationMonitor {
    private var monitor: Any?
    private let onKeyDown: (UInt16, NSEvent.ModifierFlags) -> Bool

    init(onKeyDown: @escaping (UInt16, NSEvent.ModifierFlags) -> Bool) {
        self.onKeyDown = onKeyDown
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.onKeyDown(event.keyCode, event.modifierFlags) {
                return nil // Consume event
            }
            return event
        }
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - SwiftUI Choose Dialog

struct SwiftUIChooseDialog: View {
    let prompt: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let onComplete: (Set<Int>) -> Void
    let onCancel: () -> Void

    @State private var selectedIndices: Set<Int> = []
    @State private var focusedIndex: Int = 0

    init(prompt: String, choices: [String], descriptions: [String]?, allowMultiple: Bool, defaultSelection: String?, onComplete: @escaping (Set<Int>) -> Void, onCancel: @escaping () -> Void) {
        self.prompt = prompt
        self.choices = choices
        self.descriptions = descriptions
        self.allowMultiple = allowMultiple
        self.defaultSelection = defaultSelection
        self.onComplete = onComplete
        self.onCancel = onCancel

        if let defaultSel = defaultSelection, let idx = choices.firstIndex(of: defaultSel) {
            _selectedIndices = State(initialValue: [idx])
            _focusedIndex = State(initialValue: idx)
        }
    }

    var body: some View {
        DialogContainer(keyHandler: handleKeyPress) {
            VStack(spacing: 0) {
                headerView
                choicesScrollView
                footerView
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(prompt))
            .accessibilityHint(allowMultiple ? "Select one or more options. Use arrow keys to navigate, Space to select." : "Select one option. Use arrow keys to navigate, Space to select.")
        }
    }

    private var headerView: some View {
        Text(prompt)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(Theme.Colors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
    }

    private var choicesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                        SwiftUIChoiceCard(
                            title: choice,
                            subtitle: descriptions?[safe: index],
                            isSelected: selectedIndices.contains(index),
                            isMultiSelect: allowMultiple,
                            isFocused: focusedIndex == index,
                            onTap: { toggleSelection(at: index) }
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 500)
            .onChange(of: focusedIndex) { newIndex in
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private var footerView: some View {
        DialogFooter(
            hints: [
                KeyboardHint(key: "↑↓", label: "navigate"),
                KeyboardHint(key: "Space", label: "select"),
                KeyboardHint(key: "⏎", label: "done"),
                KeyboardHint(key: "Esc", label: "cancel")
            ],
            buttons: [
                .init("Cancel", action: onCancel),
                .init("Done", isPrimary: true, isDisabled: selectedIndices.isEmpty, showReturnHint: true, action: { onComplete(selectedIndices) })
            ]
        )
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case 48: // Tab
            if modifiers.contains(.shift) {
                if focusedIndex > 0 { focusedIndex -= 1 }
            } else {
                if focusedIndex < choices.count - 1 { focusedIndex += 1 }
            }
            return true
        case 125: // Down arrow
            if focusedIndex < choices.count - 1 { focusedIndex += 1 }
            return true
        case 126: // Up arrow
            if focusedIndex > 0 { focusedIndex -= 1 }
            return true
        case 49: // Space - toggle selection
            toggleSelection(at: focusedIndex)
            return true
        case 36: // Enter/Return - confirm if selection made
            if !selectedIndices.isEmpty { onComplete(selectedIndices) }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(at index: Int) {
        if allowMultiple {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
        } else {
            selectedIndices = [index]
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < current ? Theme.Colors.accentBlue : Theme.Colors.cardBackground)
                    .frame(height: index < current ? 6 : 4)
                    .overlay(
                        Capsule()
                            .strokeBorder(index < current ? Color.clear : Theme.Colors.border.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .frame(height: 6)
        .accessibilityLabel(Text("Step \(current) of \(total)"))
        .accessibilityValue(Text("\(Int(Double(current) / Double(total) * 100)) percent complete"))
    }
}

// MARK: - Question Section (shared component)

struct QuestionSection: View {
    let question: QuestionItem
    @Binding var selectedIndices: Set<Int>
    @Binding var focusedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    SwiftUIChoiceCard(
                        title: option.label,
                        subtitle: option.description,
                        isSelected: selectedIndices.contains(index),
                        isMultiSelect: question.multiSelect,
                        isFocused: focusedIndex == index,
                        onTap: { toggleSelection(at: index) }
                    )
                    .id(index)
                }
            }
        }
    }

    private func toggleSelection(at index: Int) {
        if question.multiSelect {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
        } else {
            selectedIndices = [index]
        }
    }
}

// MARK: - Wizard Mode Dialog

struct SwiftUIWizardDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @State private var currentIndex = 0
    @State private var answers: [String: Set<Int>] = [:]
    @State private var focusedOptionIndex: Int = 0

    private var currentQuestion: QuestionItem { questions[currentIndex] }
    private var currentAnswer: Set<Int> { answers[currentQuestion.id] ?? [] }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == questions.count - 1 }

    var body: some View {
        DialogContainer(keyHandler: handleKeyPress) {
            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(current: currentIndex + 1, total: questions.count)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                // Progress text
                Text("\(currentIndex + 1) of \(questions.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.bottom, 16)

                // Question content
                ScrollViewReader { proxy in
                    ScrollView {
                        QuestionSection(
                            question: currentQuestion,
                            selectedIndices: Binding(
                                get: { currentAnswer },
                                set: { answers[currentQuestion.id] = $0 }
                            ),
                            focusedIndex: $focusedOptionIndex
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 420)
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                // Navigation buttons
                VStack(spacing: 8) {
                    KeyboardHintsView(hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "⏎", label: isLast ? "done" : "next"),
                        KeyboardHint(key: "Esc", label: "cancel")
                    ])
                    HStack(spacing: 10) {
                        if isFirst {
                            SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                        } else {
                            SwiftUIModernButton(title: "Back", isPrimary: false, action: goBack)
                        }

                        if isLast {
                            SwiftUIModernButton(title: "Done", isPrimary: true, isDisabled: currentAnswer.isEmpty, showReturnHint: true, action: {
                                onComplete(answers)
                            })
                        } else {
                            SwiftUIModernButton(title: "Next", isPrimary: true, isDisabled: currentAnswer.isEmpty, showReturnHint: true, action: goNext)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onChange(of: currentIndex) { _ in focusedOptionIndex = 0 }
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case 53: // ESC
            onCancel()
            return true
        case 48: // Tab
            if modifiers.contains(.shift) {
                if focusedOptionIndex > 0 { focusedOptionIndex -= 1 }
            } else {
                if focusedOptionIndex < currentQuestion.options.count - 1 { focusedOptionIndex += 1 }
            }
            return true
        case 125: // Down arrow
            if focusedOptionIndex < currentQuestion.options.count - 1 { focusedOptionIndex += 1 }
            return true
        case 126: // Up arrow
            if focusedOptionIndex > 0 { focusedOptionIndex -= 1 }
            return true
        case 49: // Space - toggle selection
            toggleSelection(at: focusedOptionIndex)
            return true
        case 36: // Enter/Return - next or complete
            if !currentAnswer.isEmpty {
                if isLast { onComplete(answers) } else { goNext() }
            }
            return true
        case 124: // Right arrow - next question
            if !isLast && !currentAnswer.isEmpty { goNext() }
            return true
        case 123: // Left arrow - previous question
            if !isFirst { goBack() }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(at index: Int) {
        var current = answers[currentQuestion.id] ?? []
        if currentQuestion.multiSelect {
            if current.contains(index) {
                current.remove(index)
            } else {
                current.insert(index)
            }
        } else {
            current = [index]
        }
        answers[currentQuestion.id] = current
    }

    private func goNext() {
        currentIndex += 1
    }

    private func goBack() {
        currentIndex -= 1
    }
}

// MARK: - Accordion Mode Dialog

struct AccordionSection: View {
    let question: QuestionItem
    let isExpanded: Bool
    let isAnswered: Bool
    @Binding var selectedIndices: Set<Int>
    @Binding var focusedIndex: Int
    let onToggle: () -> Void
    let onAutoAdvance: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(isAnswered ? Theme.Colors.accentBlue : Theme.Colors.cardBackground)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .strokeBorder(isAnswered ? Color.clear : Theme.Colors.border, lineWidth: 2)
                            )

                        if isAnswered {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .fill(Theme.Colors.textMuted)
                                .frame(width: 6, height: 6)
                        }
                    }

                    Text(question.question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHovered ? Theme.Colors.cardHover : Theme.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .onHover { hovering in
                if reduceMotion {
                    isHovered = hovering
                } else {
                    withAnimation(.easeOut(duration: 0.12)) {
                        isHovered = hovering
                    }
                }
            }

            // Expanded content
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        SwiftUIChoiceCard(
                            title: option.label,
                            subtitle: option.description,
                            isSelected: selectedIndices.contains(index),
                            isMultiSelect: question.multiSelect,
                            isFocused: focusedIndex == index,
                            onTap: { toggleSelection(at: index) }
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
    }

    private func toggleSelection(at index: Int) {
        if question.multiSelect {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
        } else {
            selectedIndices = [index]
            // Auto-advance to next section after single-select
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onAutoAdvance()
            }
        }
    }
}

struct SwiftUIAccordionDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var expandedId: String?
    @State private var answers: [String: Set<Int>] = [:]
    @State private var focusedOptionIndex: Int = 0

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    private var expandedQuestion: QuestionItem? {
        questions.first { $0.id == expandedId }
    }

    var body: some View {
        DialogContainer(keyHandler: handleKeyPress) {
            VStack(spacing: 0) {
                // Header with progress
                HStack {
                    Text("Questions")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Text("\(answeredCount)/\(questions.count) answered")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Accordion sections
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(questions, id: \.id) { question in
                                AccordionSection(
                                    question: question,
                                    isExpanded: expandedId == question.id,
                                    isAnswered: !(answers[question.id] ?? []).isEmpty,
                                    selectedIndices: Binding(
                                        get: { answers[question.id] ?? [] },
                                        set: { answers[question.id] = $0 }
                                    ),
                                    focusedIndex: Binding(
                                        get: { expandedId == question.id ? focusedOptionIndex : -1 },
                                        set: { if expandedId == question.id { focusedOptionIndex = $0 } }
                                    ),
                                    onToggle: { toggleExpanded(question.id) },
                                    onAutoAdvance: { advanceToNextSection(from: question.id) }
                                )
                                .id(question.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 450)
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                // Footer buttons
                VStack(spacing: 8) {
                    KeyboardHintsView(hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "Tab", label: "section"),
                        KeyboardHint(key: "⏎", label: "done")
                    ])
                    HStack(spacing: 10) {
                        SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                        SwiftUIModernButton(title: "Done", isPrimary: true, isDisabled: answeredCount == 0, showReturnHint: true, action: {
                            onComplete(answers)
                        })
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            if let first = questions.first {
                expandedId = first.id
            }
        }
        .onChange(of: expandedId) { _ in focusedOptionIndex = 0 }
    }

    private func toggleExpanded(_ questionId: String) {
        if reduceMotion {
            expandedId = expandedId == questionId ? nil : questionId
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                expandedId = expandedId == questionId ? nil : questionId
            }
        }
    }

    private func advanceToNextSection(from questionId: String) {
        guard let currentIdx = questions.firstIndex(where: { $0.id == questionId }) else { return }
        let nextIdx = currentIdx + 1
        if nextIdx < questions.count {
            if reduceMotion {
                expandedId = questions[nextIdx].id
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    expandedId = questions[nextIdx].id
                }
            }
        }
        // If last question, stay expanded (user can click Done)
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        // ESC to cancel
        if keyCode == 53 {
            onCancel()
            return true
        }

        guard let question = expandedQuestion else {
            // No section expanded - Tab opens first/last, Enter completes if any answers
            if keyCode == 48 {
                if modifiers.contains(.shift) {
                    if let last = questions.last { toggleExpanded(last.id) }
                } else {
                    if let first = questions.first { toggleExpanded(first.id) }
                }
                return true
            }
            if keyCode == 36 && answeredCount > 0 {
                onComplete(answers)
                return true
            }
            return false
        }

        switch keyCode {
        case 125: // Down arrow
            if focusedOptionIndex < question.options.count - 1 { focusedOptionIndex += 1 }
            return true
        case 126: // Up arrow
            if focusedOptionIndex > 0 { focusedOptionIndex -= 1 }
            return true
        case 49: // Space - toggle selection
            toggleSelection(for: question, at: focusedOptionIndex)
            return true
        case 36: // Enter/Return - advance or complete
            let currentAnswered = !(answers[question.id] ?? []).isEmpty
            if currentAnswered {
                if let idx = questions.firstIndex(where: { $0.id == expandedId }) {
                    if idx + 1 < questions.count {
                        advanceToNextSection(from: question.id)
                        return true
                    }
                }
            }
            if answeredCount > 0 { onComplete(answers) }
            return true
        case 48: // Tab - navigate accordion sections
            if let idx = questions.firstIndex(where: { $0.id == expandedId }) {
                let nextIdx = modifiers.contains(.shift)
                    ? (idx - 1 + questions.count) % questions.count
                    : (idx + 1) % questions.count
                toggleExpanded(questions[nextIdx].id)
            }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(for question: QuestionItem, at index: Int) {
        var current = answers[question.id] ?? []
        if question.multiSelect {
            if current.contains(index) {
                current.remove(index)
            } else {
                current.insert(index)
            }
        } else {
            current = [index]
        }
        answers[question.id] = current
    }
}

// MARK: - Questionnaire Mode Dialog (all visible)

struct SwiftUIQuestionnaireDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @State private var answers: [String: Set<Int>] = [:]
    @State private var focusedQuestionIndex: Int = 0
    @State private var focusedOptionIndex: Int = 0

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    private var focusedQuestion: QuestionItem? {
        guard focusedQuestionIndex < questions.count else { return nil }
        return questions[focusedQuestionIndex]
    }

    var body: some View {
        DialogContainer(keyHandler: handleKeyPress) {
            VStack(spacing: 0) {
                // Header with progress
                HStack {
                    Text("Questions")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Text("\(answeredCount)/\(questions.count) answered")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // All questions visible
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { qIndex, question in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Question number badge
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(!(answers[question.id] ?? []).isEmpty ? Theme.Colors.accentBlue : Theme.Colors.border)
                                                .frame(width: 24, height: 24)

                                            Text("\(qIndex + 1)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }

                                        Text(question.question)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.bottom, 12)
                                    .id("q\(qIndex)")

                                    // Options
                                    VStack(spacing: 8) {
                                        ForEach(Array(question.options.enumerated()), id: \.offset) { optIndex, option in
                                            SwiftUIChoiceCard(
                                                title: option.label,
                                                subtitle: option.description,
                                                isSelected: (answers[question.id] ?? []).contains(optIndex),
                                                isMultiSelect: question.multiSelect,
                                                isFocused: focusedQuestionIndex == qIndex && focusedOptionIndex == optIndex,
                                                onTap: { toggleSelection(questionId: question.id, optionIndex: optIndex, multiSelect: question.multiSelect) }
                                            )
                                            .id("q\(qIndex)o\(optIndex)")
                                        }
                                    }
                                }

                                if qIndex < questions.count - 1 {
                                    Rectangle()
                                        .fill(Theme.Colors.border.opacity(0.8))
                                        .frame(height: 1)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .frame(maxHeight: 450)
                    .onChange(of: focusedQuestionIndex) { _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("q\(focusedQuestionIndex)", anchor: .top)
                        }
                    }
                    .onChange(of: focusedOptionIndex) { _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("q\(focusedQuestionIndex)o\(focusedOptionIndex)", anchor: .center)
                        }
                    }
                }

                // Footer buttons
                VStack(spacing: 8) {
                    KeyboardHintsView(hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "Tab", label: "question"),
                        KeyboardHint(key: "⏎", label: "done")
                    ])
                    HStack(spacing: 10) {
                        SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                        SwiftUIModernButton(title: "Done", isPrimary: true, isDisabled: answeredCount == 0, showReturnHint: true, action: {
                            onComplete(answers)
                        })
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    private func toggleSelection(questionId: String, optionIndex: Int, multiSelect: Bool) {
        var current = answers[questionId] ?? []
        if multiSelect {
            if current.contains(optionIndex) {
                current.remove(optionIndex)
            } else {
                current.insert(optionIndex)
            }
        } else {
            current = [optionIndex]
        }
        answers[questionId] = current
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        // ESC to cancel
        if keyCode == 53 {
            onCancel()
            return true
        }

        guard let question = focusedQuestion else { return false }

        switch keyCode {
        case 125: // Down arrow - next option or next question
            if focusedOptionIndex < question.options.count - 1 {
                focusedOptionIndex += 1
            } else if focusedQuestionIndex < questions.count - 1 {
                focusedQuestionIndex += 1
                focusedOptionIndex = 0
            }
            return true
        case 126: // Up arrow - previous option or previous question
            if focusedOptionIndex > 0 {
                focusedOptionIndex -= 1
            } else if focusedQuestionIndex > 0 {
                focusedQuestionIndex -= 1
                focusedOptionIndex = questions[focusedQuestionIndex].options.count - 1
            }
            return true
        case 49: // Space - toggle selection
            toggleSelection(questionId: question.id, optionIndex: focusedOptionIndex, multiSelect: question.multiSelect)
            return true
        case 48: // Tab - next/previous question
            if modifiers.contains(.shift) {
                if focusedQuestionIndex > 0 {
                    focusedQuestionIndex -= 1
                    focusedOptionIndex = 0
                }
            } else {
                if focusedQuestionIndex < questions.count - 1 {
                    focusedQuestionIndex += 1
                    focusedOptionIndex = 0
                }
            }
            return true
        case 36: // Enter/Return - complete if any answers
            if answeredCount > 0 {
                onComplete(answers)
            }
            return true
        default:
            return false
        }
    }
}

// MARK: - Borderless Window that Accepts Keyboard

class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            NSApp.stopModal(withCode: .cancel)
        } else {
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        NSApp.stopModal(withCode: .cancel)
    }
}

// MARK: - Draggable Window Background

class DraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 8, dy: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.cornerRadius, yRadius: Theme.cornerRadius)
        Theme.windowBackground.setFill()
        path.fill()
    }
}

// MARK: - Modern Button

class ModernButton: NSView {
    var title: String
    var isPrimary: Bool
    var isDestructive: Bool
    var onClick: (() -> Void)?

    private var isHovered = false
    private var isPressed = false
    private var isFocused = false
    private var trackingArea: NSTrackingArea?

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    init(title: String, isPrimary: Bool = false, isDestructive: Bool = false) {
        self.title = title
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        super.init(frame: .zero)
        setupTracking()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupTracking() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        isPressed = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if isPressed && isHovered {
            onClick?()
        }
        isPressed = false
        needsDisplay = true
    }

    override func becomeFirstResponder() -> Bool {
        isFocused = true
        needsDisplay = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isFocused = false
        needsDisplay = true
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 36 { // Space or Enter
            onClick?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.buttonRadius, yRadius: Theme.buttonRadius)

        let bgColor: NSColor
        if isPrimary {
            if isPressed {
                bgColor = Theme.accentBlue.blended(withFraction: 0.3, of: .black) ?? Theme.accentBlue
            } else if isHovered {
                bgColor = Theme.accentBlue.blended(withFraction: 0.15, of: .white) ?? Theme.accentBlue
            } else {
                bgColor = Theme.accentBlue
            }
        } else if isDestructive {
            if isPressed {
                bgColor = Theme.accentRed.blended(withFraction: 0.3, of: .black) ?? Theme.accentRed
            } else if isHovered {
                bgColor = Theme.accentRed.blended(withFraction: 0.15, of: .white) ?? Theme.accentRed
            } else {
                bgColor = Theme.accentRed.withAlphaComponent(0.2)
            }
        } else {
            if isPressed {
                bgColor = Theme.cardSelected
            } else if isHovered {
                bgColor = Theme.cardHover
            } else {
                bgColor = Theme.cardBackground
            }
        }

        bgColor.setFill()
        path.fill()

        if !isPrimary {
            Theme.border.setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        // Draw focus ring
        if isFocused {
            let focusPath = NSBezierPath(roundedRect: rect.insetBy(dx: -2, dy: -2), xRadius: Theme.buttonRadius + 1, yRadius: Theme.buttonRadius + 1)
            Theme.accentBlue.setStroke()
            focusPath.lineWidth = 2
            focusPath.stroke()
        }

        let textColor: NSColor = isPrimary ? .white : (isDestructive ? Theme.accentRed : Theme.textPrimary)
        let font = NSFont.systemFont(ofSize: 15, weight: isPrimary ? .semibold : .medium)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let size = (title as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )

        (title as NSString).draw(in: textRect, withAttributes: attrs)
    }
}

// MARK: - Modern Choice Card

class ChoiceCard: NSView {
    var title: String
    var subtitle: String?
    var isSelected = false
    var onClick: (() -> Void)?

    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    override var mouseDownCanMoveWindow: Bool { false }

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        super.init(frame: .zero)
        setupTracking()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupTracking() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.cardRadius, yRadius: Theme.cardRadius)

        let bgColor: NSColor
        if isSelected {
            bgColor = Theme.accentBlue.withAlphaComponent(0.25)
        } else if isHovered {
            bgColor = Theme.cardHover
        } else {
            bgColor = Theme.cardBackground
        }

        bgColor.setFill()
        path.fill()

        let borderColor = isSelected ? Theme.accentBlue : Theme.border
        borderColor.setStroke()
        path.lineWidth = isSelected ? 2 : 1
        path.stroke()

        // Checkmark circle for selected
        if isSelected {
            let checkSize: CGFloat = 20
            let checkRect = NSRect(x: bounds.width - checkSize - 12, y: (bounds.height - checkSize) / 2, width: checkSize, height: checkSize)
            let checkPath = NSBezierPath(ovalIn: checkRect)
            Theme.accentBlue.setFill()
            checkPath.fill()

            let checkmarkPath = NSBezierPath()
            let cx = checkRect.midX
            let cy = checkRect.midY
            checkmarkPath.move(to: NSPoint(x: cx - 4, y: cy))
            checkmarkPath.line(to: NSPoint(x: cx - 1, y: cy - 3))
            checkmarkPath.line(to: NSPoint(x: cx + 4, y: cy + 3))
            NSColor.white.setStroke()
            checkmarkPath.lineWidth = 2
            checkmarkPath.lineCapStyle = .round
            checkmarkPath.lineJoinStyle = .round
            checkmarkPath.stroke()
        }

        // Text
        let textX: CGFloat = 16
        let maxTextWidth = bounds.width - 50

        let titleFont = NSFont.systemFont(ofSize: 14, weight: .medium)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: Theme.textPrimary
        ]

        if let subtitle = subtitle, !subtitle.isEmpty {
            let titleY = bounds.height / 2 + 4
            let titleRect = NSRect(x: textX, y: titleY, width: maxTextWidth, height: 18)
            (title as NSString).draw(in: titleRect, withAttributes: titleAttrs)

            let subtitleFont = NSFont.systemFont(ofSize: 11, weight: .regular)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: Theme.textSecondary
            ]
            let subtitleY = bounds.height / 2 - 14
            let subtitleRect = NSRect(x: textX, y: subtitleY, width: maxTextWidth, height: 14)
            (subtitle as NSString).draw(in: subtitleRect, withAttributes: subtitleAttrs)
        } else {
            let titleSize = (title as NSString).size(withAttributes: titleAttrs)
            let titleY = (bounds.height - titleSize.height) / 2
            let titleRect = NSRect(x: textX, y: titleY, width: maxTextWidth, height: titleSize.height)
            (title as NSString).draw(in: titleRect, withAttributes: titleAttrs)
        }
    }
}

// MARK: - Modern Text Field

class ModernTextField: NSView {
    var placeholder: String
    var isSecure: Bool
    var text: String {
        get { textField.stringValue }
        set { textField.stringValue = newValue }
    }

    override var mouseDownCanMoveWindow: Bool { false }

    private let textField: NSTextField

    init(placeholder: String = "", isSecure: Bool = false, defaultValue: String = "") {
        self.placeholder = placeholder
        self.isSecure = isSecure

        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }

        super.init(frame: .zero)

        textField.stringValue = defaultValue
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.textColor = Theme.textPrimary

        addSubview(textField)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        textField.frame = bounds.insetBy(dx: 14, dy: 0)
        textField.frame.origin.y = (bounds.height - 22) / 2
        textField.frame.size.height = 22
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)

        Theme.inputBackground.setFill()
        path.fill()

        Theme.border.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    func makeFirstResponder(in window: NSWindow) {
        window.makeFirstResponder(textField)
    }
}

// MARK: - Speech Delegate

class SpeechCompletionDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        super.init()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onComplete()
    }
}

// MARK: - Dialog Manager

class DialogManager {
    static let shared = DialogManager()
    private var clientName = "MCP"
    private var userSettings = UserSettings.load()

    func setClientName(_ name: String) {
        clientName = name
    }

    /// Returns the effective position - user setting always overrides passed-in position
    private func effectivePosition(_ requestedPosition: String) -> String {
        return userSettings.position
    }

    private func buildTitle(_ baseTitle: String) -> String {
        "\(clientName)"
    }

    private func createWindow(width: CGFloat, height: CGFloat) -> (NSWindow, DraggableView) {
        let window = BorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true

        let bgView = DraggableView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = bgView

        return (window, bgView)
    }

    private func positionWindow(_ window: NSWindow, position: String) {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        let x: CGFloat
        switch position {
        case "left":
            x = screenFrame.minX + 40
        case "right":
            x = screenFrame.maxX - windowFrame.width - 40
        default:
            x = screenFrame.midX - windowFrame.width / 2
        }

        let y = screenFrame.maxY - windowFrame.height - 80
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Confirm Dialog (SwiftUI)

    func confirm(_ request: ConfirmRequest) -> ConfirmResponse {
        NSApp.setActivationPolicy(.accessory)

        var result: ConfirmResponse?
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 360

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Create SwiftUI dialog
        let swiftUIDialog = SwiftUIConfirmDialog(
            title: request.title,
            message: request.message,
            confirmLabel: request.confirmLabel,
            cancelLabel: request.cancelLabel,
            onConfirm: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: true, cancelled: false, dismissed: false, answer: request.confirmLabel, comment: nil)
                NSApp.stopModal()
            },
            onCancel: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: request.cancelLabel, comment: nil)
                NSApp.stopModal()
            }
        )

        // Embed SwiftUI in NSHostingView
        let hostingView = NSHostingView(rootView: swiftUIDialog)
        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: true, dismissed: true, answer: nil, comment: nil)
    }

    // MARK: - Choose Dialog (SwiftUI)

    func choose(_ request: ChooseRequest) -> ChoiceResponse {
        NSApp.setActivationPolicy(.accessory)

        var result: ChoiceResponse?
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 520

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Create SwiftUI dialog
        let swiftUIDialog = SwiftUIChooseDialog(
            prompt: request.prompt,
            choices: request.choices,
            descriptions: request.descriptions,
            allowMultiple: request.allowMultiple,
            defaultSelection: request.defaultSelection,
            onComplete: { selectedIndices in
                if selectedIndices.isEmpty {
                    result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil)
                } else if request.allowMultiple {
                    let selected = selectedIndices.sorted().map { request.choices[$0] }
                    let descs = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    result = ChoiceResponse(dialogType: "choose", answer: .multiple(selected), cancelled: false, dismissed: false, description: nil, descriptions: descs, comment: nil)
                } else if let idx = selectedIndices.first {
                    result = ChoiceResponse(dialogType: "choose", answer: .single(request.choices[idx]), cancelled: false, dismissed: false, description: request.descriptions?[safe: idx], descriptions: nil, comment: nil)
                }
                NSApp.stopModal()
            },
            onCancel: {
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil)
                NSApp.stopModal()
            }
        )

        // Embed SwiftUI in NSHostingView
        let hostingView = NSHostingView(rootView: swiftUIDialog)
        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: true, description: nil, descriptions: nil, comment: nil)
    }

    // MARK: - Text Input Dialog (Full AppKit with Modern Design)

    func textInput(_ request: TextInputRequest) -> TextInputResponse {
        NSApp.setActivationPolicy(.accessory)

        var result: TextInputResponse?
        let windowWidth: CGFloat = 420

        // Calculate prompt height dynamically
        let promptFont = NSFont.systemFont(ofSize: 13)
        let promptAttrs: [NSAttributedString.Key: Any] = [.font: promptFont]
        let promptMaxWidth = windowWidth - 48
        let promptSize = (request.prompt as NSString).boundingRect(
            with: NSSize(width: promptMaxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: promptAttrs
        )
        let promptHeight = max(20, ceil(promptSize.height) + 8)

        // Calculate total window height based on content
        let topPadding: CGFloat = 32
        let iconSize: CGFloat = 56
        let iconToTitle: CGFloat = 20
        let titleHeight: CGFloat = 28
        let titleToPrompt: CGFloat = 12
        let promptToInput: CGFloat = 32
        let inputHeight: CGFloat = 48
        let inputToButtons: CGFloat = 28
        let buttonHeight: CGFloat = 48
        let bottomPadding: CGFloat = 24

        let windowHeight = topPadding + iconSize + iconToTitle + titleHeight + titleToPrompt + promptHeight + promptToInput + inputHeight + inputToButtons + buttonHeight + bottomPadding

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        var yPos = windowHeight - topPadding

        // Icon
        yPos -= iconSize
        let iconBg = NSView(frame: NSRect(x: (windowWidth - iconSize) / 2, y: yPos, width: iconSize, height: iconSize))
        iconBg.wantsLayer = true
        iconBg.layer?.backgroundColor = Theme.accentBlue.withAlphaComponent(0.15).cgColor
        iconBg.layer?.cornerRadius = iconSize / 2
        contentView.addSubview(iconBg)

        let iconImage = NSImageView(frame: NSRect(x: (windowWidth - 24) / 2, y: yPos + 16, width: 24, height: 24))
        iconImage.image = NSImage(systemSymbolName: request.hidden ? "lock.fill" : "text.cursor", accessibilityDescription: nil)
        iconImage.contentTintColor = Theme.accentBlue
        contentView.addSubview(iconImage)

        // Title
        yPos -= iconToTitle + titleHeight
        let titleLabel = NSTextField(labelWithString: request.title)
        titleLabel.frame = NSRect(x: 24, y: yPos, width: windowWidth - 48, height: titleHeight)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Theme.textPrimary
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)

        // Prompt (wrapping text)
        yPos -= titleToPrompt + promptHeight
        let promptLabel = NSTextField(wrappingLabelWithString: request.prompt)
        promptLabel.frame = NSRect(x: 24, y: yPos, width: promptMaxWidth, height: promptHeight)
        promptLabel.font = promptFont
        promptLabel.textColor = Theme.textSecondary
        promptLabel.alignment = .center
        promptLabel.maximumNumberOfLines = 0
        promptLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(promptLabel)

        // Text Field
        yPos -= promptToInput + inputHeight
        let inputField = StyledTextField(isSecure: request.hidden, defaultValue: request.defaultValue)
        inputField.frame = NSRect(x: 28, y: yPos, width: windowWidth - 56, height: inputHeight)
        contentView.addSubview(inputField)

        // Keyboard hints
        let hintsLabel = NSTextField(labelWithString: "⏎ submit  •  Esc cancel")
        hintsLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        hintsLabel.textColor = Theme.textMuted
        hintsLabel.alignment = .center
        hintsLabel.frame = NSRect(x: 20, y: bottomPadding + buttonHeight + 8, width: windowWidth - 40, height: 16)
        contentView.addSubview(hintsLabel)

        // Buttons
        let buttonSpacing: CGFloat = 10
        let sideMargin: CGFloat = 20
        let buttonWidth = (windowWidth - sideMargin * 2 - buttonSpacing - 16) / 2

        let cancelButton = ModernButton(title: "Cancel", isPrimary: false)
        cancelButton.frame = NSRect(x: sideMargin + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(cancelButton)

        let submitButton = ModernButton(title: "Submit ⏎", isPrimary: true)
        submitButton.frame = NSRect(x: sideMargin + buttonWidth + buttonSpacing + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(submitButton)

        submitButton.onClick = {
            result = TextInputResponse(dialogType: "textInput", answer: inputField.textField.stringValue, cancelled: false, dismissed: false, comment: nil)
            NSApp.stopModal()
        }

        cancelButton.onClick = {
            result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil)
            NSApp.stopModal()
        }

        // Set up key view loop for tab navigation
        inputField.textField.nextKeyView = cancelButton
        cancelButton.nextKeyView = submitButton
        submitButton.nextKeyView = inputField.textField
        window.initialFirstResponder = inputField.textField

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Focus text field with proper modal run loop scheduling
        let modes: [RunLoop.Mode] = [.default, .modalPanel]
        RunLoop.current.perform(inModes: modes) {
            window.makeFirstResponder(inputField.textField)
        }

        // Handle Enter to submit, Escape to cancel
        let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 36 { // Enter/Return
                result = TextInputResponse(dialogType: "textInput", answer: inputField.textField.stringValue, cancelled: false, dismissed: false, comment: nil)
                NSApp.stopModal()
                return nil
            } else if event.keyCode == 53 { // Escape
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil)
                NSApp.stopModal()
                return nil
            }
            return event
        }

        NSApp.runModal(for: window)
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
        window.close()

        return result ?? TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: true, comment: nil)
    }

    // MARK: - Notify (using osascript for bundle-free notifications)

    func notify(_ request: NotifyRequest) -> NotifyResponse {
        let title = buildTitle(request.title)
        var script = "display notification \"\(escapeForAppleScript(request.message))\" with title \"\(escapeForAppleScript(title))\""
        if let subtitle = request.subtitle {
            script += " subtitle \"\(escapeForAppleScript(subtitle))\""
        }
        if request.sound {
            script += " sound name \"default\""
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let success: Bool
        do {
            try process.run()
            process.waitUntilExit()
            success = process.terminationStatus == 0
        } catch {
            success = false
        }

        return NotifyResponse(dialogType: "notify", success: success)
    }

    private func escapeForAppleScript(_ str: String) -> String {
        return str.replacingOccurrences(of: "\\", with: "\\\\")
                  .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - Speak

    func speak(_ request: SpeakRequest) -> SpeakResponse {
        let semaphore = DispatchSemaphore(value: 0)
        let speechDelegate = SpeechCompletionDelegate { semaphore.signal() }

        let synth = AVSpeechSynthesizer()
        synth.delegate = speechDelegate

        let utterance = AVSpeechUtterance(string: request.text)
        let normalizedRate = Float(request.rate - 50) / 450.0
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, normalizedRate))

        if let voiceName = request.voice {
            let voices = AVSpeechSynthesisVoice.speechVoices()
            if let voice = voices.first(where: { $0.name.lowercased().contains(voiceName.lowercased()) }) {
                utterance.voice = voice
            }
        }

        synth.speak(utterance)
        semaphore.wait()

        // Keep references alive until speech completes
        _ = synth
        _ = speechDelegate

        return SpeakResponse(dialogType: "speak", success: true)
    }

    // MARK: - Multi-Question Dialog

    func questions(_ request: QuestionsRequest) -> QuestionsResponse {
        NSApp.setActivationPolicy(.accessory)

        var result: QuestionsResponse?
        let windowWidth: CGFloat = 460
        let windowHeight: CGFloat = 560

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Convert answers from Set<Int> to response format
        func buildResponse(answers: [String: Set<Int>], cancelled: Bool, dismissed: Bool) -> QuestionsResponse {
            var responseAnswers: [String: StringOrStrings] = [:]
            var completedCount = 0

            for question in request.questions {
                if let indices = answers[question.id], !indices.isEmpty {
                    completedCount += 1
                    let labels = indices.sorted().map { question.options[$0].label }
                    if question.multiSelect {
                        responseAnswers[question.id] = .multiple(labels)
                    } else if let first = labels.first {
                        responseAnswers[question.id] = .single(first)
                    }
                }
            }

            return QuestionsResponse(dialogType: "questions", answers: responseAnswers, cancelled: cancelled, dismissed: dismissed, completedCount: completedCount)
        }

        let onComplete: ([String: Set<Int>]) -> Void = { answers in
            result = buildResponse(answers: answers, cancelled: false, dismissed: false)
            NSApp.stopModal()
        }

        let onCancel: () -> Void = {
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: false, completedCount: 0)
            NSApp.stopModal()
        }

        // Create appropriate dialog based on mode
        let hostingView: NSHostingView<AnyView>
        switch request.mode {
        case "wizard":
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIWizardDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        case "accordion":
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIAccordionDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        default: // "questionnaire"
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIQuestionnaireDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        }

        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: true, completedCount: 0)
    }
}

// MARK: - Main

// MARK: - Pulse Response

struct PulseResponse: Codable {
    let success: Bool
}

func setupEditMenu() {
    let mainMenu = NSMenu()
    let editMenuItem = NSMenuItem()
    editMenuItem.submenu = NSMenu(title: "Edit")

    let editMenu = editMenuItem.submenu!
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

    mainMenu.addItem(editMenuItem)
    NSApp.mainMenu = mainMenu
}

func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    setupEditMenu()

    let args = CommandLine.arguments
    guard args.count >= 2 else {
        fputs("Usage: dialog-cli <command> [json]\n", stderr)
        fputs("Commands: confirm, choose, textInput, notify, speak, questions, pulse\n", stderr)
        exit(1)
    }

    let command = args[1]

    // Handle pulse command separately (no JSON needed)
    if command == "pulse" {
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.speak.pulse"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        let response = PulseResponse(success: true)
        if let data = try? JSONEncoder().encode(response),
           let output = String(data: data, encoding: .utf8) {
            print(output)
        }
        exit(0)
    }

    guard args.count >= 3 else {
        fputs("Usage: dialog-cli <command> <json>\n", stderr)
        fputs("Commands: confirm, choose, textInput, notify, speak, questions, pulse\n", stderr)
        exit(1)
    }

    let jsonInput = args[2]

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    let manager = DialogManager.shared

    if let clientName = ProcessInfo.processInfo.environment["MCP_CLIENT_NAME"] {
        manager.setClientName(clientName)
    }

    guard let jsonData = jsonInput.data(using: .utf8) else {
        fputs("Invalid JSON input\n", stderr)
        exit(1)
    }

    var outputData: Data?

    switch command {
    case "confirm":
        guard let request = try? decoder.decode(ConfirmRequest.self, from: jsonData) else {
            fputs("Invalid confirm request\n", stderr)
            exit(1)
        }
        let response = manager.confirm(request)
        outputData = try? encoder.encode(response)

    case "choose":
        guard let request = try? decoder.decode(ChooseRequest.self, from: jsonData) else {
            fputs("Invalid choose request\n", stderr)
            exit(1)
        }
        let response = manager.choose(request)
        outputData = try? encoder.encode(response)

    case "textInput":
        guard let request = try? decoder.decode(TextInputRequest.self, from: jsonData) else {
            fputs("Invalid textInput request\n", stderr)
            exit(1)
        }
        let response = manager.textInput(request)
        outputData = try? encoder.encode(response)

    case "notify":
        guard let request = try? decoder.decode(NotifyRequest.self, from: jsonData) else {
            fputs("Invalid notify request\n", stderr)
            exit(1)
        }
        let response = manager.notify(request)
        outputData = try? encoder.encode(response)

    case "speak":
        guard let request = try? decoder.decode(SpeakRequest.self, from: jsonData) else {
            fputs("Invalid speak request\n", stderr)
            exit(1)
        }
        let response = manager.speak(request)
        outputData = try? encoder.encode(response)

    case "questions":
        guard let request = try? decoder.decode(QuestionsRequest.self, from: jsonData) else {
            fputs("Invalid questions request\n", stderr)
            exit(1)
        }
        let response = manager.questions(request)
        outputData = try? encoder.encode(response)

    default:
        fputs("Unknown command: \(command)\n", stderr)
        exit(1)
    }

    if let data = outputData, let output = String(data: data, encoding: .utf8) {
        print(output)
    } else {
        fputs("Failed to encode response\n", stderr)
        exit(1)
    }
}

main()
