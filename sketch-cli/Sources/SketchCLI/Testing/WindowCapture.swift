import AppKit
import SwiftUI

enum WindowCapture {
    @MainActor
    static func capture(layout: GridLayout, title: String, outputPath: String) -> Bool {
        let editorState = SketchEditorState(layout: layout)
        let dialog = SketchEditorView(
            state: editorState,
            titleText: title,
            descriptionText: nil
        )

        let hostingView = NSHostingView(rootView: dialog)
        hostingView.layout()

        let windowWidth: CGFloat = 700
        let windowHeight: CGFloat = 500

        let window = BorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = false

        let bgView = DraggableView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        window.contentView = bgView

        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        hostingView.autoresizingMask = [.width, .height]
        bgView.addSubview(hostingView)

        window.makeKeyAndOrderFront(nil)

        // Let SwiftUI render
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))

        let success = captureWindowImage(window, to: outputPath)
        window.orderOut(nil)
        window.close()

        return success
    }

    private static func captureWindowImage(_ window: NSWindow, to path: String) -> Bool {
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            CGWindowID(window.windowNumber),
            [.bestResolution]
        ) else {
            return false
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        return FileManager.default.createFile(atPath: path, contents: pngData)
    }
}
