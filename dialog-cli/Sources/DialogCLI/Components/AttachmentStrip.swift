import AppKit
import SwiftUI

/// The row of attached images, shown between the dialog's content and its
/// footer whenever anything has been pasted or dropped.
///
/// Deliberately a chassis element rather than something each dialog builds:
/// attaching an image is orthogonal to what is being asked, so a confirm and a
/// form should show it the same way, and a skin restyles it in one place. It
/// occupies no room at all when empty — an attachment strip that reserved
/// space would change every dialog's height for a feature most calls never
/// use.
struct AttachmentStrip: View {
    @ObservedObject private var store = AttachmentStore.shared

    private let thumbnail: CGFloat = 44

    var body: some View {
        if !store.isEmpty || store.lastRejection != nil {
            VStack(alignment: .leading, spacing: 6) {
                if !store.isEmpty {
                    HStack(spacing: 8) {
                        Text(caption)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.Colors.textMuted)
                        Spacer(minLength: 8)
                        Button("Clear") { store.clear() }
                            .buttonStyle(.plain)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.textMuted)
                            .help("Remove every attached image")
                    }

                    // Horizontal rather than wrapping: the count is capped at
                    // eight, and a row that grows downward would push the
                    // footer around every time an image lands.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.items) { item in
                                cell(item)
                            }
                        }
                    }
                    .frame(height: thumbnail + 4)
                }

                if let rejection = store.lastRejection {
                    Text(rejection)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var caption: String {
        let count = store.items.count
        return count == 1 ? "1 IMAGE ATTACHED" : "\(count) IMAGES ATTACHED"
    }

    private func cell(_ item: DialogAttachment) -> some View {
        Image(nsImage: item.thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbnail, height: thumbnail)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            // The remove control sits on the thumbnail rather than beside it so
            // the row's width stays a function of the count alone.
            .overlay(alignment: .topTrailing) {
                Button {
                    store.remove(item.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .background(Circle().fill(Theme.Colors.windowBackground))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
                .help("Remove \(item.name)")
            }
            .help("\(item.name) — \(Int(item.pixelSize.width))×\(Int(item.pixelSize.height))")
            .accessibilityLabel(Text("Attached image \(item.name)"))
    }
}
