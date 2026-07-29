import AppKit
import SwiftUI

/// The two surfaces that ask nothing.
///
/// Both close themselves after a fixed lifetime and answer to Escape and
/// nothing else. Neither carries tools or ways out, so the mark loses its
/// lower arms and keeps only the stems and the top return — the same frame,
/// with less on it.
///
/// §5.6 turns on one distinction: a preview MUST NOT read as an alert. The
/// brand already has the answer. A notification takes the amber caret, which
/// is the colour of being paged; the preview takes the single-colour cut of
/// the mark, the same 45% the menu-bar glyph uses when nothing is waiting.
struct CaretTransient<Content: View>: View {
    let kind: CaretKind
    let title: String
    let alerting: Bool
    @ViewBuilder var content: () -> Content

    @Environment(\.caretPalette) private var palette
    @State private var escape: KeyboardNavigationMonitor?
    @State private var remaining: Double = 1
    @State private var clock: Timer?

    private var inset: CGFloat { CaretStyle.caretRail / 2 }
    private var armInset: CGFloat { CaretStyle.u(9) }

    private var badge: String {
        var parts = [kind.badge]
        if let project = DialogManager.shared.getProjectName() { parts.append(project) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: CaretStyle.u(20)) {
                Text(badge)
                    .font(Font(CaretStyle.mono))
                    .kerning(CaretStyle.mono.pointSize * CaretStyle.railTracking)
                    .foregroundStyle(alerting ? palette.caret : palette.inkMuted)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.leading, armInset)
                    .help(DialogManager.shared.getProjectPath() ?? "")

                Spacer(minLength: 0)

                // §3.1: reachable from every surface, including read-only ones.
                // §10.10 asks that the divergence be predictable rather than
                // hidden, so the description says where it goes.
                CaretToolMark(key: nil, name: "REPORT", help: "Report a bug (opens in browser)") {
                    GitHubReporter.openIssue(description: "", screenshotData: nil, copyToClipboard: false)
                }
                .padding(.trailing, armInset)
            }
            .padding(.horizontal, inset)
            .frame(height: CaretStyle.u(16))

            // The title is clamped to one line and truncated here, unlike
            // every interactive surface (§3.3).
            Text(title)
                .font(Font(CaretStyle.question))
                .kerning(CaretStyle.question.pointSize * CaretStyle.displayTracking)
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, CaretStyle.u(14))

            CaretChannel(cap: CaretStyle.u(150)) { content() }
                .padding(.top, CaretStyle.u(6))
        }
        .padding(.horizontal, CaretStyle.caretRail + CaretStyle.gutter)
        .padding(.top, inset + CaretStyle.u(10))
        .padding(.bottom, inset + CaretStyle.u(12))
        .frame(minWidth: CaretStyle.u(330), alignment: .topLeading)
        .background(palette.window)
        .clipShape(RoundedRectangle(cornerRadius: CaretStyle.windowRadius, style: .continuous))
        .overlay(
            CaretRails(
                topLeading: armInset + CaretStyle.width(badge, font: CaretStyle.mono, tracking: CaretStyle.railTracking) + CaretStyle.u(10),
                topTrailing: armInset + CaretToolMark.width(key: nil, name: "REPORT") + CaretStyle.u(10),
                bottomLeading: CaretArmStyle(length: CaretStyle.u(26)),
                bottomTrailing: CaretArmStyle(length: CaretStyle.u(26)),
                focusRect: nil,
                // §10.15: the lifetime is fixed and cannot be paused from
                // here, but it can at least be visible. It runs down the same
                // stem the cooldown does, in the same direction.
                cooldown: remaining,
                progressTone: alerting ? palette.caret : palette.caretQuiet
            )
        )
        .onAppear(perform: start)
        .onDisappear { clock?.invalidate(); escape = nil }
    }

    private func start() {
        // Transient surfaces never trigger a cooldown, so Escape works from
        // the first frame.
        escape = KeyboardNavigationMonitor { key, _ in
            guard key == KeyCode.escape else { return false }
            NSApp.stopModal()
            return true
        }
        let opened = Date()
        let lifetime: Double = 4.0
        let timer = Timer(timeInterval: 1.0 / 20.0, repeats: true) { _ in
            MainActor.assumeIsolated {
                remaining = min(1, Date().timeIntervalSince(opened) / lifetime)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        clock = timer
        remaining = 0
    }
}

/// Notify (§5.5). §10.3 leaves the one surface where a link would matter most
/// rendering it as literal text; this applies §3.4 there too.
struct CaretNotifyView: View {
    let spec: NotifySpec
    @Environment(\.caretPalette) private var palette

    var body: some View {
        CaretTransient(kind: .notify, title: spec.title, alerting: true) {
            CaretBody(raw: spec.body)
        }
    }
}

/// Response preview (§5.6). Read-only, and deliberately *not* formatted: the
/// body is the exact outgoing text, and marking it up would misrepresent what
/// is being sent. That is the other half of the §10.3 decision.
struct CaretPreviewView: View {
    let spec: PreviewSpec
    @Environment(\.caretPalette) private var palette

    var body: some View {
        CaretTransient(kind: .preview, title: "Response Preview", alerting: false) {
            Text(spec.body)
                .font(Font(CaretStyle.monoCode))
                .foregroundStyle(palette.inkSecond)
                .textSelection(.enabled)
                .lineSpacing(CaretStyle.u(3))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: CaretStyle.proseMeasure, alignment: .leading)
        }
    }
}
