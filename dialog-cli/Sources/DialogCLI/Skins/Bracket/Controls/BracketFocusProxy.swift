import AppKit
import SwiftUI

/// The AppKit half of every Bracket control.
///
/// Arrow and Tab navigation only exist for `NSView`s registered with
/// `FocusManager`, but the skin wants SwiftUI layout (wrapping labels, reflowing
/// rows). So each control is a SwiftUI view with one of these pinned behind it
/// as a background: it inherits the control's exact frame — so focus-scrolling
/// and hit geometry are right — contributes nothing to layout, and publishes
/// first-responder changes back up. Pointer handling stays in SwiftUI.
final class FocusProxyView: NSView {
    var isButton = false
    var isFocusable = true
    var onFocusChange: (Bool) -> Void = { _ in }
    var onSpace: () -> Void = {}

    private var registered = false

    /// §3.11 — a disabled control is skipped by Tab, never focused-and-inert.
    override var acceptsFirstResponder: Bool { isFocusable }
    override var canBecomeKeyView: Bool { isFocusable }

    /// Purely a focus anchor: the SwiftUI content in front owns the pointer.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            guard !registered else { return }
            registered = true
            if isButton {
                FocusManager.shared.registerButton(self)
            } else {
                FocusManager.shared.registerContent(self)
            }
        } else if registered {
            registered = false
            FocusManager.shared.unregister(self)
        }
    }

    override func becomeFirstResponder() -> Bool {
        guard isFocusable else { return false }
        onFocusChange(true)
        return true
    }

    override func resignFirstResponder() -> Bool {
        onFocusChange(false)
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == " " {
            onSpace()
            return
        }
        super.keyDown(with: event)
    }
}

struct FocusProxy: NSViewRepresentable {
    var isButton: Bool
    var isFocusable: Bool
    var onFocusChange: (Bool) -> Void
    var onSpace: () -> Void

    func makeNSView(context: Context) -> FocusProxyView {
        let view = FocusProxyView()
        apply(to: view)
        return view
    }

    func updateNSView(_ view: FocusProxyView, context: Context) {
        apply(to: view)
    }

    private func apply(to view: FocusProxyView) {
        view.isButton = isButton
        view.isFocusable = isFocusable
        view.onFocusChange = { focused in
            DispatchQueue.main.async { onFocusChange(focused) }
        }
        view.onSpace = onSpace
    }

    static func dismantleNSView(_ view: FocusProxyView, coordinator: ()) {
        FocusManager.shared.unregister(view)
    }
}

extension View {
    /// Registers this control for keyboard navigation without touching layout.
    func bracketFocusable(
        isButton: Bool,
        isFocusable: Bool = true,
        onFocusChange: @escaping (Bool) -> Void,
        onSpace: @escaping () -> Void
    ) -> some View {
        background(
            FocusProxy(
                isButton: isButton,
                isFocusable: isFocusable,
                onFocusChange: onFocusChange,
                onSpace: onSpace
            )
        )
    }
}
