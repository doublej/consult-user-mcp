import AppKit
import SwiftUI

// MARK: - Console Panel Bridge

/// Invisible view that manages a child NSPanel for the tweak console.
/// The panel floats beside the dialog without affecting its layout or size.
struct ConsolePanelBridge: NSViewRepresentable {
    let showConsole: Bool
    let position: DialogPosition
    let editEvent: EditEvent?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let coordinator = context.coordinator

        guard let parentWindow = nsView.window else { return }

        if showConsole {
            if coordinator.panel == nil {
                coordinator.panel = createPanel(parent: parentWindow)
            }
            coordinator.updateContent(editEvent: editEvent)
            positionPanel(coordinator.panel!, relativeTo: parentWindow)

            if !coordinator.panel!.isVisible {
                parentWindow.addChildWindow(coordinator.panel!, ordered: position == .right ? .below : .above)
                coordinator.panel!.orderFront(nil)
            }
        } else if let panel = coordinator.panel, panel.isVisible {
            parentWindow.removeChildWindow(panel)
            panel.orderOut(nil)
        }
    }

    private func createPanel(parent: NSWindow) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 270, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = parent.level
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        return panel
    }

    private func positionPanel(_ panel: NSPanel, relativeTo parent: NSWindow) {
        let parentFrame = parent.frame
        let panelWidth: CGFloat = 270
        let gap: CGFloat = 8

        let x: CGFloat
        if position == .right {
            x = parentFrame.minX - panelWidth - gap
        } else {
            x = parentFrame.maxX + gap
        }

        let panelHeight = parentFrame.height
        let y = parentFrame.origin.y

        let newFrame = NSRect(x: x, y: y, width: panelWidth, height: panelHeight)
        if panel.frame != newFrame {
            panel.setFrame(newFrame, display: true)
        }
    }

    // MARK: - Coordinator

    final class Coordinator {
        var panel: NSPanel?
        private var hostingView: NSHostingView<ConsolePanelContent>?

        func updateContent(editEvent: EditEvent?) {
            guard let panel else { return }

            if let hostingView {
                hostingView.rootView = ConsolePanelContent(editEvent: editEvent)
            } else {
                let view = NSHostingView(rootView: ConsolePanelContent(editEvent: editEvent))
                view.frame = panel.contentView!.bounds
                view.autoresizingMask = [.width, .height]
                panel.contentView!.addSubview(view)
                hostingView = view
            }
        }

        deinit {
            if let panel {
                panel.parent?.removeChildWindow(panel)
                panel.orderOut(nil)
            }
        }
    }
}

// MARK: - Console Panel Content

private struct ConsolePanelContent: View {
    let editEvent: EditEvent?

    var body: some View {
        TweakConsoleView(editEvent: editEvent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.Colors.border.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
    }
}
