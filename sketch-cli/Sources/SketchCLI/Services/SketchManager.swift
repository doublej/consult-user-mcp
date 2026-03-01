import AppKit
import SwiftUI

class SketchManager {
    static let shared = SketchManager()

    @MainActor
    func propose(layout: GridLayout, title: String?, description: String?) -> LayoutResponse {
        var coloredLayout = layout
        coloredLayout.blocks = ColorPalette.assignColors(to: coloredLayout.blocks)

        let editorState = SketchEditorState(layout: coloredLayout)
        let dialog = SketchEditorView(
            state: editorState,
            titleText: title ?? "Layout Sketch",
            descriptionText: description
        )

        let hostingView = NSHostingView(rootView: dialog)
        hostingView.layout()

        let windowWidth: CGFloat = 700
        let windowHeight: CGFloat = 500

        let window = BorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 500, height: 400)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = false

        // Connect keyboard shortcuts
        window.onUndoRequested = { [weak editorState] in
            MainActor.assumeIsolated { editorState?.undo() }
        }
        window.onRedoRequested = { [weak editorState] in
            MainActor.assumeIsolated { editorState?.redo() }
        }
        window.onAcceptRequested = { [weak editorState] in
            MainActor.assumeIsolated {
                guard let editorState else { return }
                editorState.status = editorState.layout == editorState.initialLayout ? "accepted" : "modified"
                NSApp.stopModal()
            }
        }

        let bgView = DraggableView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        window.contentView = bgView

        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        hostingView.autoresizingMask = [.width, .height]
        bgView.addSubview(hostingView)

        positionWindow(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        guard editorState.status != "cancelled" else {
            return LayoutResponse(
                status: "cancelled",
                layout: nil, ascii: nil, image: nil, summary: nil, changes: nil
            )
        }

        let finalLayout = editorState.layout
        let ascii = AsciiRenderer.render(finalLayout)
        let summary = DescriptionRenderer.render(finalLayout)
        let image = SvgRenderer.render(finalLayout)
        let changes = diffLayouts(original: coloredLayout, modified: finalLayout)

        return LayoutResponse(
            status: changes.isEmpty ? "accepted" : "modified",
            layout: finalLayout,
            ascii: ascii,
            image: image,
            summary: summary,
            changes: changes.isEmpty ? nil : changes
        )
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.maxY - windowFrame.height - 80
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func diffLayouts(original: GridLayout, modified: GridLayout) -> [String] {
        var changes: [String] = []

        let origById = Dictionary(uniqueKeysWithValues: original.blocks.map { ($0.id, $0) })
        let modById = Dictionary(uniqueKeysWithValues: modified.blocks.map { ($0.id, $0) })

        for (id, modBlock) in modById {
            guard let origBlock = origById[id] else {
                changes.append("Added \"\(modBlock.label)\" at (\(modBlock.x),\(modBlock.y)) size \(modBlock.w)\u{00D7}\(modBlock.h)")
                continue
            }
            if origBlock.x != modBlock.x || origBlock.y != modBlock.y {
                changes.append("Moved \"\(modBlock.label)\" from (\(origBlock.x),\(origBlock.y)) to (\(modBlock.x),\(modBlock.y))")
            }
            if origBlock.w != modBlock.w || origBlock.h != modBlock.h {
                changes.append("Resized \"\(modBlock.label)\" from \(origBlock.w)\u{00D7}\(origBlock.h) to \(modBlock.w)\u{00D7}\(modBlock.h)")
            }
            if origBlock.label != modBlock.label {
                changes.append("Renamed \"\(origBlock.label)\" to \"\(modBlock.label)\"")
            }
        }

        for (id, origBlock) in origById where modById[id] == nil {
            changes.append("Removed \"\(origBlock.label)\"")
        }

        return changes
    }
}
