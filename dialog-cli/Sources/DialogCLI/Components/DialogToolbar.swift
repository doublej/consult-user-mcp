import SwiftUI
import AppKit

// MARK: - Snooze Duration

enum SnoozeDuration: Int, CaseIterable {
    case oneMinute = 1
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60

    var label: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .oneHour: return "1h"
        }
    }
}

// MARK: - Snooze Scope

/// The one decision a snooze still has: whether it covers this consult only,
/// or every agent waiting behind it.
///
/// Unticked — the default — snoozing answers *this* question later and leaves
/// the shared snooze window untouched, so nothing else is silenced. Ticked, it
/// writes the window the way a snooze always used to.
///
/// Every skin's snooze panel draws the same control with its own type and
/// colour. The state lives on `DialogManager`, which is where the snooze
/// callbacks read it; nothing else writes it, so a local mirror stays true.
struct SnoozeScopeToggle: View {
    var font: Font
    var tint: Color
    var muted: Color
    /// Skins that set their labels in the mono rail face want the caption in
    /// capitals; the default style wants it as written.
    var label: String = "Also hold other consults"

    @State private var on = DialogManager.shared.snoozeHoldsOthers

    var body: some View {
        Button {
            on.toggle()
            DialogManager.shared.snoozeHoldsOthers = on
        } label: {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(on ? tint : muted, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(on ? tint : Color.clear)
                    )
                    .frame(width: 13, height: 13)
                    .overlay {
                        if on {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.Colors.cardBackground)
                        }
                    }
                Text(label)
                    .font(font)
                    .foregroundColor(on ? tint : muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(on ? "on" : "off"))
        .accessibilityHint(Text("When off, snoozing defers only this question."))
    }
}

// MARK: - Dialog Toolbar

struct DialogToolbar: View {
    @Binding var expandedTool: ToolbarTool?
    let currentDialogType: String
    let hasFeedback: Bool
    let onSnooze: (Int) -> Void
    let onOpenFeedback: () -> Void
    let onAskDifferently: (String) -> Void

    /// Only snooze still uses the inline-expansion toolbar pattern. Feedback
    /// now opens the slide-out pane via `onOpenFeedback`.
    enum ToolbarTool {
        case snooze
    }

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            if expandedTool == .snooze {
                snoozePanel
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(spacing: 12) {
                ToolbarButton(
                    icon: "clock.arrow.circlepath",
                    label: "Snooze",
                    isActive: expandedTool == .snooze,
                    action: { toggleSnooze() }
                )

                ToolbarButton(
                    icon: hasFeedback ? "bubble.left.fill" : "bubble.left",
                    label: "Feedback",
                    isActive: false,
                    action: onOpenFeedback
                )

                AskDifferentlyButton(
                    currentDialogType: currentDialogType,
                    onSelect: onAskDifferently
                )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Theme.Colors.cardBackground)
        .onChange(of: expandedTool) { _ in
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }
    }

    private func toggleSnooze() {
        if reduceMotion {
            expandedTool = expandedTool == .snooze ? nil : .snooze
        } else {
            withAnimation(.easeOut(duration: Theme.Animation.overlay)) {
                expandedTool = expandedTool == .snooze ? nil : .snooze
            }
        }
    }

    private var snoozePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask me again in:")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach(SnoozeDuration.allCases, id: \.rawValue) { duration in
                    SnoozeButton(label: duration.label) {
                        onSnooze(duration.rawValue)
                    }
                }
            }

            SnoozeScopeToggle(
                font: .system(size: 11),
                tint: Theme.Colors.accentBlue,
                muted: Theme.Colors.textSecondary
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Toolbar Button

private struct ToolbarButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isActive ? Theme.Colors.accentBlue : Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Theme.Colors.accentBlue.opacity(0.15) : (isHovered ? Theme.Colors.cardHover : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Ask Differently Button

private struct AskDifferentlyButton: View {
    let currentDialogType: String
    let onSelect: (String) -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            if let type = AskDifferentlyMenuHelper.show(currentDialogType: currentDialogType) {
                onSelect(type)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 12, weight: .medium))
                Text("Ask differently")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isHovered ? Theme.Colors.accentBlue : Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Theme.Colors.cardHover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Snooze Button

private struct SnoozeButton: View {
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isHovered ? .white : Theme.Colors.textPrimary)
                .frame(width: 48, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Theme.Colors.accentBlue : Theme.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Ask Differently NSMenu Helper

/// Shows the "Ask differently" NSMenu and returns the selected type.
/// Uses NSMenuDelegate instead of target-action because the dialog runs
/// in NSApp.runModal, which blocks action delivery to non-window targets.
class AskDifferentlyMenuHelper: NSObject, NSMenuDelegate {
    private var selectedType: String?
    private var lastHighlightedItem: NSMenuItem?
    private static var active: AskDifferentlyMenuHelper?

    static let options: [(label: String, type: String)] = [
        ("Confirmation", "confirm"),
        ("Single Select", "pick"),
        ("Multi Select", "pick-multi"),
        ("Text Input", "text"),
        ("Password", "text-hidden"),
        ("Wizard Form", "form-wizard"),
    ]

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        lastHighlightedItem = item
    }

    func menuDidClose(_ menu: NSMenu) {
        if let item = lastHighlightedItem, item.isEnabled {
            selectedType = item.representedObject as? String
        }
    }

    static func show(currentDialogType: String) -> String? {
        guard let window = NSApp.keyWindow ?? NSApp.modalWindow,
              let view = window.contentView else { return nil }

        let helper = AskDifferentlyMenuHelper()
        active = helper

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = helper

        for option in options {
            let item = NSMenuItem(title: option.label, action: nil, keyEquivalent: "")
            item.representedObject = option.type
            item.isEnabled = option.type != currentDialogType
            if option.type == currentDialogType {
                item.state = .on
            }
            menu.addItem(item)
        }

        let point = NSPoint(x: 20, y: 50)
        menu.popUp(positioning: nil, at: point, in: view)

        let result = helper.selectedType
        active = nil
        return result
    }
}
