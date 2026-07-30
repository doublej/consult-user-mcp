import AppKit
import SwiftUI

/// The attached-images row, in the caret skin's own language.
///
/// The chassis strip in `Components/AttachmentStrip.swift` is the classic one
/// and uses system type; dropped into this surface it reads as a control panel
/// borrowed from another application. This is the same information — count,
/// thumbnails, a way to take one back — set in the mono caption face every
/// other section header here uses, with the caret rule instead of a border.
///
/// Collapses to nothing when empty, like the note panel above it: a row that
/// reserved space would change the height of every dialog for a feature most
/// calls never touch.
struct CaretAttachmentStrip: View {
    @ObservedObject private var store = AttachmentStore.shared
    @Environment(\.caretPalette) private var palette

    private var side: CGFloat { CaretStyle.u(30) }

    var body: some View {
        if !store.isEmpty || store.lastRejection != nil {
            VStack(alignment: .leading, spacing: CaretStyle.u(6)) {
                if !store.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: CaretStyle.u(12)) {
                        Text(caption)
                            .font(Font(CaretStyle.monoTiny))
                            .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                            .foregroundStyle(palette.caret)
                        Spacer(minLength: CaretStyle.u(12))
                        Text("CLEAR")
                            .font(Font(CaretStyle.monoTiny))
                            .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                            .foregroundStyle(palette.inkMuted)
                            .contentShape(Rectangle())
                            .onTapGesture { store.clear() }
                            .help("Remove every attached image")
                    }

                    HStack(spacing: CaretStyle.u(8)) {
                        ForEach(store.items) { item in
                            cell(item)
                        }
                        Spacer(minLength: 0)
                    }
                }

                if let rejection = store.lastRejection {
                    Text(rejection)
                        .font(Font(CaretStyle.monoTiny))
                        .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                        .foregroundStyle(palette.inkMuted)
                }
            }
            .padding(.horizontal, CaretStyle.caretRail + CaretStyle.gutter)
            .padding(.bottom, CaretStyle.u(14))
        }
    }

    private var caption: String {
        store.items.count == 1 ? "1 IMAGE" : "\(store.items.count) IMAGES"
    }

    private func cell(_ item: DialogAttachment) -> some View {
        Image(nsImage: item.thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: side, height: side)
            .clipped()
            // The caret rule under each thumbnail, the same mark a selected
            // option row carries — so an attachment reads as something chosen
            // rather than as a floating tile.
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(palette.caret)
                    .frame(height: CaretStyle.hair)
            }
            .contentShape(Rectangle())
            .onTapGesture { store.remove(item.id) }
            .help("\(item.name) — \(Int(item.pixelSize.width))×\(Int(item.pixelSize.height)). Click to remove.")
            .accessibilityLabel(Text("Attached image \(item.name)"))
    }
}
