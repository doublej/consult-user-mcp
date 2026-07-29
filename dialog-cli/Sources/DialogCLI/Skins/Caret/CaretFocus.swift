import AppKit
import SwiftUI

/// The coordinate space the caret is positioned in.
enum CaretSpace {
    static let surface = "caret.surface"
}

/// Where the caret should stand. Published by whichever target holds focus.
struct CaretFocusKey: PreferenceKey {
    static let defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        if let next = nextValue() { value = next }
    }
}

/// A transparent, focusable, clickable target laid over drawn content.
///
/// It exists because arrow and Tab navigation only reach `NSView`s registered
/// with `FocusManager`, and because §3.9 wants press *and* release on the same
/// target with a drag-off cancelling. It draws nothing at all — the treatment
/// it drives is drawn in SwiftUI underneath it.
final class CaretTargetView: NSView {
    var isContent = true
    var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            if !isEnabled, window?.firstResponder === self { window?.makeFirstResponder(nil) }
            // `canBecomeKeyView` flipped, so the ring's cache is stale.
            FocusManager.shared.unregister(self)
            if window != nil { registerWithFocusRing() }
        }
    }
    var takesReturn = false
    var onActivate: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    var onPressChange: ((Bool) -> Void)?
    var onHoverChange: ((Bool) -> Void)?

    private var tracking: NSTrackingArea?

    // §3.9: an unavailable action is not focusable and Tab skips it.
    override var acceptsFirstResponder: Bool { isEnabled }
    override var canBecomeKeyView: Bool { isEnabled }
    override var isFlipped: Bool { true }
    // §2.5: clicking an inactive surface focuses it first, then delivers the click.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            FocusManager.shared.unregister(self)
        } else {
            registerWithFocusRing()
        }
    }

    private func registerWithFocusRing() {
        if isContent {
            FocusManager.shared.registerContent(self)
        } else {
            FocusManager.shared.registerButton(self)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) { onHoverChange?(true) }
    override func mouseExited(with event: NSEvent) { onHoverChange?(false) }

    override func becomeFirstResponder() -> Bool {
        onFocusChange?(true)
        return true
    }

    override func resignFirstResponder() -> Bool {
        onFocusChange?(false)
        return true
    }

    /// Space, and Return only where §4.4 sends it — a commit that is
    /// unavailable falls the key through to whatever holds focus. Arrows and
    /// Tab are routed centrally; a target that installed its own event
    /// monitor would fight the router.
    override func keyDown(with event: NSEvent) {
        guard isEnabled, !CooldownManager.shared.isCoolingDown else {
            super.keyDown(with: event)
            return
        }
        if event.keyCode == KeyCode.space {
            onActivate?()
            return
        }
        if event.keyCode == KeyCode.returnKey {
            if takesReturn { onActivate?() }
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        // §4.6: clicks are swallowed during the cooldown.
        guard isEnabled, !CooldownManager.shared.isCoolingDown else { return }
        var inside = true
        onPressChange?(true)
        while let next = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) {
            let point = convert(next.locationInWindow, from: nil)
            let nowInside = bounds.contains(point)
            if nowInside != inside {
                inside = nowInside
                onPressChange?(inside)
            }
            if next.type == .leftMouseUp { break }
        }
        onPressChange?(false)
        guard inside else { return }
        window?.makeFirstResponder(self)
        onActivate?()
    }
}

struct CaretTarget: NSViewRepresentable {
    var isContent: Bool
    var isEnabled: Bool = true
    /// §4.4 sends Return to the focused control when commit is unavailable.
    var takesReturn: Bool = false
    var onActivate: () -> Void
    var onFocusChange: (Bool) -> Void = { _ in }
    var onPressChange: (Bool) -> Void = { _ in }
    var onHoverChange: (Bool) -> Void = { _ in }
    /// Set once the view exists so a surface can put focus somewhere on open.
    var register: ((NSView) -> Void)? = nil

    func makeNSView(context: Context) -> CaretTargetView {
        let view = CaretTargetView()
        view.isContent = isContent
        view.isEnabled = isEnabled && !context.environment.caretInert
        view.takesReturn = takesReturn
        view.onActivate = onActivate
        view.onFocusChange = onFocusChange
        view.onPressChange = onPressChange
        view.onHoverChange = onHoverChange
        register?(view)
        return view
    }

    func updateNSView(_ view: CaretTargetView, context: Context) {
        view.isEnabled = isEnabled && !context.environment.caretInert
        view.takesReturn = takesReturn
        view.onActivate = onActivate
        view.onFocusChange = onFocusChange
        view.onPressChange = onPressChange
        view.onHoverChange = onHoverChange
    }
}

extension View {
    /// Publishes this view's rectangle to the caret while it holds focus.
    func caretStop(_ focused: Bool) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: CaretFocusKey.self,
                    value: focused ? geo.frame(in: .named(CaretSpace.surface)) : nil
                )
            }
        )
    }
}
