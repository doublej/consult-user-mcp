import SwiftUI

/// Covers an expired dialog once the agent has stopped waiting (see
/// `DialogExpiry`). The window stays on screen so the user learns what
/// happened, but every control underneath is inert — the overlay's scrim
/// intercepts clicks and `DialogKeyRouter` swallows keys.
struct ExpiredOverlay: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)

            VStack(spacing: 0) {
                DialogHeader(
                    icon: "clock.badge.xmark",
                    title: "The agent has moved on",
                    body: "No answer arrived in time, so the agent continued with its best guess. This dialog can no longer deliver an answer.",
                    iconColor: Theme.Colors.accentRed
                )
                .padding(.horizontal, 20)

                DialogFooter(
                    hints: [KeyboardHint(key: "esc", label: "close")],
                    buttons: [
                        .init("Close", isPrimary: true, showReturnHint: true, action: onClose),
                    ]
                )
            }
            .background(Theme.Colors.windowBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
            .padding(16)
        }
    }
}
