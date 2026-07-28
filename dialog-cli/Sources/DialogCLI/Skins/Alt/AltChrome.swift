import AppKit
import SwiftUI

// MARK: - Rail

/// Thin accent stripe down the left edge of every Alt dialog. The single
/// strongest cue that this is not the Classic skin.
struct AltRail: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.Colors.accentBlue, Theme.Colors.accentBlue.opacity(0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: AltMetrics.railWidth)
    }
}

// MARK: - Panel

/// Rail + content. Wrap the whole dialog body in this.
struct AltPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 0) {
            AltRail()
            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Kicker

/// Uppercase monospaced dialog-type label. Replaces Classic's circular icon.
struct AltKicker: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: AltMetrics.kickerSize, weight: .semibold, design: .monospaced))
            .tracking(1.4)
            .foregroundColor(Theme.Colors.accentBlue)
            .lineLimit(1)
    }
}

// MARK: - Header

/// Left-aligned kicker / title / body stack.
struct AltHeader: View {
    let kicker: String
    let title: String
    let bodyText: String?

    init(kicker: String, title: String, body: String? = nil) {
        self.kicker = kicker
        self.title = title
        self.bodyText = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AltKicker(text: kicker)

            Text(title)
                .font(.system(size: AltMetrics.titleSize, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .frame(idealWidth: AltMetrics.contentIdealWidth, maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let text = bodyText, !text.isEmpty {
                Text(AttributedString(MarkdownParser.parse(text, fontSize: AltMetrics.bodySize, alignment: .left)))
                    .textSelection(.enabled)
                    .tint(Theme.Colors.accentBlue)
                    .frame(idealWidth: AltMetrics.contentIdealWidth, maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, AltMetrics.contentPadding)
        .padding(.top, 18)
    }
}

// MARK: - Divider

struct AltDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.border.opacity(0.45))
            .frame(height: 1)
    }
}

// MARK: - Action Bar

/// Hints left, buttons right. Classic centres its buttons; Alt does not.
struct AltActionBar: View {
    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let isPrimary: Bool
        let isDisabled: Bool
        let showReturnHint: Bool
        let action: () -> Void

        init(_ title: String, isPrimary: Bool = false, isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isPrimary = isPrimary
            self.isDisabled = isDisabled
            self.showReturnHint = showReturnHint
            self.action = action
        }
    }

    let hints: [KeyboardHint]
    let actions: [Action]

    /// Buttons are right-aligned, so they need explicit widths — a flexible
    /// HStack here would make `NSHostingView.fittingSize` non-deterministic
    /// and the window would size differently run to run.
    private func width(for action: Action) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 15, weight: action.isPrimary ? .semibold : .medium)
        var label = action.title
        if action.isPrimary && action.showReturnHint && !action.isDisabled {
            label += " ⏎"
        }
        let measured = (label as NSString).size(withAttributes: [.font: font]).width
        return max(96, ceil(measured) + 32)
    }

    var body: some View {
        VStack(spacing: 0) {
            AltDivider()

            HStack(alignment: .center, spacing: 12) {
                KeyboardHintsView(hints: hints)
                    .layoutPriority(-1)

                Spacer(minLength: 12)

                ForEach(actions) { action in
                    FocusableButton(
                        title: action.title,
                        isPrimary: action.isPrimary,
                        isDisabled: action.isDisabled,
                        showReturnHint: action.showReturnHint,
                        action: action.action
                    )
                    .frame(width: width(for: action), height: 42)
                }
            }
            .padding(.horizontal, AltMetrics.contentPadding)
            .padding(.vertical, 14)
        }
        .background(Theme.Colors.windowBackground)
    }
}

// MARK: - Pane Chrome (notify / preview)

/// Compact non-interactive pane used by notify and preview. No
/// `DialogContainer` — these panes are fire-and-forget and auto-close.
struct AltPane: View {
    let kicker: String
    let title: String
    let bodyText: String
    let accent: Color

    private var projectName: String? { DialogManager.shared.getProjectName() }
    private var projectPath: String? { DialogManager.shared.getProjectPath() }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: AltMetrics.railWidth)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(kicker.uppercased())
                        .font(.system(size: AltMetrics.kickerSize, weight: .semibold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(accent)
                    Spacer(minLength: 0)
                    if let name = projectName, let path = projectPath {
                        ProjectBadge(projectName: name, projectPath: path)
                    }
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                ScrollView {
                    Text(bodyText)
                        .font(.system(size: AltMetrics.bodySize))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: AltMetrics.paneWidth, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title). \(bodyText)"))
    }
}
