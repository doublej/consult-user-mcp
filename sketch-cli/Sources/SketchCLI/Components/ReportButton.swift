import SwiftUI

struct ReportButton: View {
    private static let accentRed = Color(nsColor: NSColor(red: 0.90, green: 0.30, blue: 0.30, alpha: 1.0))
    @State private var isHovered = false

    var body: some View {
        Button(action: { GitHubReporter.openIssue() }) {
            HStack(spacing: 4) {
                Image(systemName: "ladybug")
                    .font(.system(size: 9, weight: .medium))
                Text("Report")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isHovered ? Self.accentRed : Color(Theme.textMuted))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isHovered ? Self.accentRed.opacity(0.12) : Color.clear)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isHovered ? Self.accentRed.opacity(0.3) : Color(Theme.border).opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Report a bug or suggestion")
    }
}
