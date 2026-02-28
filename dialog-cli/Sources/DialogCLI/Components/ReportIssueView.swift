import SwiftUI
import AppKit

// MARK: - Overlay Flag (shared with BorderlessWindow)

class ReportIssueOverlayManager {
    static let shared = ReportIssueOverlayManager()
    var isShowing: Bool = false
}

// MARK: - Report Issue View (two-step)

struct ReportIssueView: View {
    @State private var description: String = ""
    @State private var step: Step = .description

    let screenshotData: Data?
    let onSubmit: (String, Bool) -> Void  // (description, copyToClipboard)
    let onCancel: () -> Void

    enum Step { case description, clipboardConfirm }

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)

            Group {
                switch step {
                case .description:
                    descriptionCard
                        .transition(reduceMotion ? .identity : .asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .clipboardConfirm:
                    clipboardCard
                        .transition(reduceMotion ? .identity : .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeOut(duration: 0.2), value: step)
            .padding(16)
        }
    }

    // MARK: Step 1 — Description

    private var descriptionCard: some View {
        VStack(spacing: 0) {
            DialogHeader(
                icon: "ladybug",
                title: "Report Issue",
                body: "Describe the problem below.",
                iconColor: Theme.Colors.accentRed
            )
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("What happened?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)

                FocusableTextField(
                    placeholder: "Briefly describe the issue...",
                    text: $description,
                    onSubmit: proceedToClipboard
                )
                .frame(height: 48)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            DialogFooter(
                hints: [KeyboardHint(key: "⏎", label: "next")],
                buttons: [
                    .init("Cancel", action: onCancel),
                    .init("Next →", isPrimary: true,
                          isDisabled: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          showReturnHint: true,
                          action: proceedToClipboard),
                ]
            )
        }
        .background(Theme.Colors.windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
    }

    // MARK: Step 2 — Clipboard Confirmation

    private var clipboardCard: some View {
        VStack(spacing: 0) {
            DialogHeader(
                icon: "doc.on.clipboard",
                title: "Save Screenshot?",
                body: "Can we save a screenshot of this dialog to your clipboard? You can paste it directly into the GitHub issue with ⌘V.",
                iconColor: Theme.Colors.accentBlue
            )
            .padding(.horizontal, 20)

            DialogFooter(
                hints: [KeyboardHint(key: "⏎", label: "copy & open")],
                buttons: [
                    .init("Skip", action: { submit(copyToClipboard: false) }),
                    .init("Yes, Copy Screenshot", isPrimary: true, showReturnHint: true,
                          action: { submit(copyToClipboard: true) }),
                ]
            )
        }
        .background(Theme.Colors.windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
    }

    // MARK: Actions

    private func proceedToClipboard() {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if reduceMotion {
            step = .clipboardConfirm
        } else {
            withAnimation(.easeOut(duration: 0.2)) { step = .clipboardConfirm }
        }
    }

    private func submit(copyToClipboard: Bool) {
        onSubmit(description.trimmingCharacters(in: .whitespacesAndNewlines), copyToClipboard)
    }
}
