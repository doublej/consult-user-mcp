import AppKit
import SwiftUI

// MARK: - Surface ground

/// The container paints no ground, so every surface starts here.
struct BracketSurface<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BracketStyle.ground)
    }
}

// MARK: - Header

/// The surface-kind label: the mark, then the §7.2 type string. It is the
/// primary answer to "each surface MUST be identifiable at a glance as the kind
/// of thing it is" — one fixed word in the same place on every surface.
struct BracketTypeLabel: View {
    var text: String
    /// The preview is the one surface whose cursor is sand, not amber — it must
    /// not read as an alert (§5.6).
    var cursorColor: Color = BracketStyle.amber

    var body: some View {
        HStack(spacing: 8) {
            BracketMark(height: 13, strokeColor: BracketStyle.inkMuted, cursorColor: cursorColor)
            Text(text)
                .font(BracketStyle.monoFont(BracketStyle.Size.label, .medium))
                .tracking(BracketStyle.labelTracking)
                .foregroundColor(BracketStyle.inkMuted)
        }
    }
}

/// The pinned part of the header: the kind label and the title. §2.3 keeps this
/// out of every scroll region.
struct BracketHeader: View {
    var typeLabel: String
    var title: String
    var cursorColor: Color = BracketStyle.amber

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BracketTypeLabel(text: typeLabel, cursorColor: cursorColor)

            if !title.isEmpty {
                Text(title)
                    .font(BracketStyle.sansFont(BracketStyle.Size.body, .semibold))
                    .foregroundColor(BracketStyle.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The agent's words, with the §3.3 presentation switch answered on two
/// channels at once: a statement is the question itself, set large and in
/// primary ink; prose is the agent explaining itself, set at body size in sand.
struct BracketBody: View {
    var text: String

    var body: some View {
        if !text.isEmpty {
            if BracketStyle.isStatement(text) {
                MarkdownText(
                    text,
                    fontSize: BracketStyle.Size.statement,
                    color: BracketStyle.ink,
                    alignment: .left
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                MarkdownText(
                    text,
                    fontSize: BracketStyle.Size.body,
                    color: BracketStyle.sand,
                    alignment: .left
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Tool strip

/// The three exits (§3.5). Replaces the shipped toolbar so the chips share the
/// skin's anatomy, and so the snooze durations can join the keyboard ring
/// (§10.7) — the shipped tray leaves them pointer-only.
struct BracketToolStrip: View {
    @Binding var expandedTool: DialogToolbar.ToolbarTool?
    var hasNote: Bool
    /// One of the six ask-differently keys; marks the current row.
    var currentShape: String
    var readiness: CGFloat
    var onSnooze: (Int) -> Void
    var onOpenFeedback: () -> Void
    var onAskDifferently: (String) -> Void

    @StateObject private var anchor = MenuAnchorHolder()

    private var snoozeExpanded: Bool { expandedTool == .snooze }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                chip("Snooze", isActive: snoozeExpanded, showsNoteMark: false) {
                    expandedTool = snoozeExpanded ? nil : .snooze
                }
                // §3.5 — Feedback never shows an active state; the only signal
                // that a note exists is its own indicator.
                chip("Feedback", isActive: false, showsNoteMark: hasNote) {
                    onOpenFeedback()
                }
                chip("Ask differently", isActive: false, showsNoteMark: false) {
                    presentShapeMenu()
                }
                .background(MenuAnchorView(holder: anchor))
            }

            if snoozeExpanded {
                snoozeTray
            }
        }
        .opacity(readiness < 1 ? 0.5 : 1)
    }

    private var snoozeTray: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask me again in:")
                .font(BracketStyle.sansFont(BracketStyle.Size.context, .regular))
                .foregroundColor(BracketStyle.inkMuted)

            HStack(spacing: 6) {
                ForEach(Self.durations, id: \.minutes) { duration in
                    BracketButton(
                        title: duration.label,
                        variant: .secondary,
                        isEnabled: true,
                        showsReturn: false,
                        readiness: readiness,
                        compact: true,
                        action: { onSnooze(duration.minutes) }
                    )
                }
            }
        }
        .padding(.leading, 2)
    }

    private static let durations: [(label: String, minutes: Int)] = [
        ("1m", 1), ("5m", 5), ("15m", 15), ("30m", 30), ("1h", 60),
    ]

    @ViewBuilder
    private func chip(
        _ title: String,
        isActive: Bool,
        showsNoteMark: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 7) {
            if showsNoteMark {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(BracketStyle.amber)
                    .frame(width: 3, height: 10)
            }
            Text(title)
                .font(BracketStyle.sansFont(BracketStyle.Size.context, .medium))
                .foregroundColor(
                    isActive ? BracketStyle.amber
                        : (showsNoteMark ? BracketStyle.ink : BracketStyle.inkMuted)
                )
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            RoundedRectangle(cornerRadius: BracketStyle.Radius.chip, style: .continuous)
                .strokeBorder(
                    isActive ? BracketStyle.amber.opacity(0.6) : BracketStyle.line,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onEnded { value in
            if value.translation.width.magnitude < 6, value.translation.height.magnitude < 6 {
                action()
            }
        })
    }

    /// §3.7 — six entries in fixed order, the current one marked and disabled.
    /// An `NSMenu` gets the arrow / Return / Escape behaviour exactly right for
    /// free, and keeps it out of the Escape unwinding stack where it does not
    /// belong.
    private func presentShapeMenu() {
        guard readiness >= 1 else { return }
        let menu = NSMenu()
        menu.font = BracketStyle.sans(BracketStyle.Size.body, .medium)
        let target = ShapeMenuTarget(onAskDifferently)
        for entry in Self.shapes {
            let item = NSMenuItem(
                title: entry.title,
                action: #selector(ShapeMenuTarget.choose(_:)),
                keyEquivalent: ""
            )
            item.target = target
            item.representedObject = entry.key
            if entry.key == currentShape {
                item.state = .on
                item.isEnabled = false
            }
            menu.addItem(item)
        }
        menu.autoenablesItems = false
        objc_setAssociatedObject(menu, &ShapeMenuTarget.key, target, .OBJC_ASSOCIATION_RETAIN)
        if let view = anchor.view {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: -6), in: view)
        }
    }

    static let shapes: [(title: String, key: String)] = [
        ("Confirmation", "confirm"),
        ("Single Select", "pick"),
        ("Multi Select", "pick-multi"),
        ("Text Input", "text"),
        ("Password", "text-hidden"),
        ("Wizard Form", "form-wizard"),
    ]
}

private final class ShapeMenuTarget: NSObject {
    static var key: UInt8 = 0
    private let handler: (String) -> Void

    init(_ handler: @escaping (String) -> Void) {
        self.handler = handler
    }

    @objc func choose(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        handler(key)
    }
}

final class MenuAnchorHolder: ObservableObject {
    weak var view: NSView?
}

struct MenuAnchorView: NSViewRepresentable {
    let holder: MenuAnchorHolder

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        holder.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Hint strip

/// §3.10, with the §10.4 defect fixed rather than reproduced: a suppressed
/// shortcut is visibly de-emphasised, everything dims during the cooldown, and
/// while a caret sits in a field the feedback hint **swaps to the chord that
/// actually works**.
struct BracketHintStrip: View {
    var leading: [(key: String, word: String)]
    var isEditing: Bool
    var isPaneOpen: Bool
    var readiness: CGFloat

    private var lettersSuppressed: Bool { isEditing || isPaneOpen || readiness < 1 }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(hints.enumerated()), id: \.offset) { index, hint in
                if index > 0 {
                    Text("·")
                        .font(BracketStyle.monoFont(BracketStyle.Size.label, .regular))
                        .foregroundColor(BracketStyle.inkMuted.opacity(0.35))
                        .padding(.horizontal, 6)
                }
                HStack(spacing: 4) {
                    Text(hint.key)
                        .font(BracketStyle.monoFont(BracketStyle.Size.label, .medium))
                        .foregroundColor(BracketStyle.inkSecondary)
                    Text(hint.word)
                        .font(BracketStyle.sansFont(BracketStyle.Size.label, .regular))
                        .foregroundColor(BracketStyle.inkMuted)
                }
                .opacity(hint.dimmed ? 0.32 : 1)
            }
        }
        .opacity(readiness < 1 ? 0.45 : 1)
        .fixedSize()
    }

    private var hints: [(key: String, word: String, dimmed: Bool)] {
        var out = leading.map { (key: $0.key, word: $0.word, dimmed: readiness < 1) }
        out.append((key: "S", word: "snooze", dimmed: lettersSuppressed))
        if isEditing || isPaneOpen {
            out.append((key: "⌘F", word: "feedback", dimmed: readiness < 1))
        } else {
            out.append((key: "F", word: "feedback", dimmed: lettersSuppressed))
        }
        out.append((key: "A", word: "ask differently", dimmed: lettersSuppressed))
        return out
    }
}

// MARK: - Action bar

/// §3.11 — secondary first, primary last, which is also the Tab order.
struct BracketActionBar<Leading: View>: View {
    var readiness: CGFloat
    @ViewBuilder var leading: () -> Leading
    var secondary: (title: String, action: () -> Void)?
    var tertiary: (title: String, action: () -> Void)?
    var primary: (title: String, isEnabled: Bool, action: () -> Void)

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            leading()
            Spacer(minLength: 12)
            if let secondary {
                BracketButton(
                    title: secondary.title,
                    variant: .secondary,
                    readiness: readiness,
                    action: secondary.action
                )
            }
            if let tertiary {
                BracketButton(
                    title: tertiary.title,
                    variant: .secondary,
                    readiness: readiness,
                    action: tertiary.action
                )
            }
            BracketButton(
                title: primary.title,
                variant: .primary,
                isEnabled: primary.isEnabled,
                showsReturn: true,
                readiness: readiness,
                action: primary.action
            )
        }
    }
}

extension BracketActionBar where Leading == EmptyView {
    init(
        readiness: CGFloat,
        secondary: (title: String, action: () -> Void)?,
        primary: (title: String, isEnabled: Bool, action: () -> Void)
    ) {
        self.init(
            readiness: readiness,
            leading: { EmptyView() },
            secondary: secondary,
            tertiary: nil,
            primary: primary
        )
    }
}

// MARK: - Small parts

/// §7.2 selection status line, adopted here (and §10.12's recommendation).
struct BracketStatusLine: View {
    var text: String

    var body: some View {
        Text(text)
            .font(BracketStyle.monoFont(BracketStyle.Size.label, .medium))
            .tracking(BracketStyle.labelTracking * 0.6)
            .foregroundColor(BracketStyle.inkMuted)
    }
}

/// §10.14 — the disabled primary explains itself, but only once the person has
/// touched the answer region, so a freshly opened surface is not pre-scolded.
struct BracketHelperLine: View {
    var text: String

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(BracketStyle.amber)
                .frame(width: 3, height: 11)
            Text(text)
                .font(BracketStyle.sansFont(BracketStyle.Size.context, .medium))
                .foregroundColor(BracketStyle.amber.opacity(0.9))
        }
    }
}

/// §5.4 — segmented, one segment per question, the current step counting as
/// complete. `Step <N> of <M>` is exposed to assistive technology.
struct BracketProgress: View {
    var step: Int
    var total: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(index < step ? BracketStyle.amber : BracketStyle.line)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel("Step \(step) of \(total)")
        .accessibilityValue("\(Int((Double(step) / Double(max(total, 1))) * 100)) percent complete")
    }
}
