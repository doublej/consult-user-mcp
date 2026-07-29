import SwiftUI

/// The two transient popups (§5.5, §5.6).
///
/// They share one arrangement and differ on exactly the channel that matters:
/// **the cursor's colour**. A notification is an announcement and carries the
/// amber cursor every interactive surface uses; the response preview is
/// informational and carries the sand one, so it cannot be mistaken for an
/// alert. Neither has a tool strip, a hint strip or action controls.
///
/// Both bodies stay **literal**. §3.4 excludes them from inline formatting and
/// §5.6 calls the preview "the exact outgoing text" — rendering markers here
/// would change a user-visible string, which §7.1 forbids a style from doing.
private struct BracketPopup: View {
    var typeLabel: String
    var cursorColor: Color
    var title: String
    var message: String

    var body: some View {
        BracketSurface {
            VStack(alignment: .leading, spacing: 0) {
                BracketTypeLabel(text: typeLabel, cursorColor: cursorColor)
                    .padding(.bottom, 11)

                if !title.isEmpty {
                    // §3.3 — clamped and truncated on the transient popups only.
                    Text(title)
                        .font(BracketStyle.sansFont(BracketStyle.Size.body, .semibold))
                        .foregroundColor(BracketStyle.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                }

                AutoSizingScrollView {
                    SelectableText(
                        message,
                        fontSize: BracketStyle.Size.body,
                        weight: .regular,
                        color: BracketStyle.sand,
                        alignment: .left
                    )
                    .padding(.trailing, 2)
                }
            }
            .padding(.horizontal, BracketStyle.Space.gutter)
            .padding(.top, 15)
            .padding(.bottom, 15)
        }
    }
}

struct BracketNotifyView: View {
    let spec: NotifySpec

    var body: some View {
        BracketPopup(
            typeLabel: "NOTIFY",
            cursorColor: BracketStyle.amber,
            title: spec.title,
            message: spec.body
        )
    }
}

struct BracketPreviewView: View {
    let spec: PreviewSpec

    var body: some View {
        BracketPopup(
            typeLabel: "PREVIEW",
            cursorColor: BracketStyle.sand,
            title: "Response Preview",
            message: spec.body
        )
    }
}
