import AppKit

// MARK: - Focus Manager

/// Centralized focus management for NSViewRepresentable views in SwiftUI
final class FocusManager {
    static let shared = FocusManager()

    private var contentViews: [NSView] = []  // Options, text fields - navigable with arrows
    private var buttonViews: [NSView] = []   // Buttons - only reachable via Tab
    private var currentContentIndex: Int = -1

    // Cached sorted views - invalidated on register/unregister
    private var cachedContentViews: [NSView]?
    private var cachedAllViews: [NSView]?

    private init() {}

    private func invalidateCache() {
        cachedContentViews = nil
        cachedAllViews = nil
    }

    private func validContentViews() -> [NSView] {
        if let cached = cachedContentViews { return cached }
        let views = contentViews
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        cachedContentViews = views
        return views
    }

    private func validAllViews() -> [NSView] {
        if let cached = cachedAllViews { return cached }
        let views = (contentViews + buttonViews)
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        cachedAllViews = views
        return views
    }

    /// Register a content view (option cards, text fields) - navigable with arrow keys
    func registerContent(_ view: NSView) {
        if !contentViews.contains(where: { $0 === view }) {
            contentViews.append(view)
            invalidateCache()
        }
    }

    /// Register a button view - only reachable via Tab, not arrows
    func registerButton(_ view: NSView) {
        if !buttonViews.contains(where: { $0 === view }) {
            buttonViews.append(view)
            invalidateCache()
        }
    }

    /// Legacy register - defaults to content
    func register(_ view: NSView) {
        registerContent(view)
    }

    /// Unregister a view from both lists
    func unregister(_ view: NSView) {
        contentViews.removeAll { $0 === view }
        buttonViews.removeAll { $0 === view }
        invalidateCache()
        updateCurrentContentIndex()
    }

    /// Clear all registered views (call when dialog closes)
    func reset() {
        contentViews.removeAll()
        buttonViews.removeAll()
        currentContentIndex = -1
        invalidateCache()
    }

    /// Move focus to next content view (arrow keys) - excludes buttons
    func focusNextContent() {
        let views = validContentViews()
        guard !views.isEmpty else { return }

        updateCurrentContentIndex()

        let nextIndex = (currentContentIndex + 1) % views.count
        if let view = views[safe: nextIndex] {
            view.window?.makeFirstResponder(view)
            currentContentIndex = nextIndex
        }
    }

    /// Move focus to previous content view (arrow keys) - excludes buttons
    func focusPreviousContent() {
        let views = validContentViews()
        guard !views.isEmpty else { return }

        updateCurrentContentIndex()

        let prevIndex = currentContentIndex <= 0 ? views.count - 1 : currentContentIndex - 1
        if let view = views[safe: prevIndex] {
            view.window?.makeFirstResponder(view)
            currentContentIndex = prevIndex
        }
    }

    /// Move focus to next view (Tab) - includes all views
    func focusNext() {
        let views = validAllViews()
        guard !views.isEmpty else { return }

        let currentIndex = findCurrentIndex(in: views)
        let nextIndex = (currentIndex + 1) % views.count
        if let view = views[safe: nextIndex] {
            view.window?.makeFirstResponder(view)
        }
    }

    /// Move focus to previous view (Shift+Tab) - includes all views
    func focusPrevious() {
        let views = validAllViews()
        guard !views.isEmpty else { return }

        let currentIndex = findCurrentIndex(in: views)
        let prevIndex = currentIndex <= 0 ? views.count - 1 : currentIndex - 1
        if let view = views[safe: prevIndex] {
            view.window?.makeFirstResponder(view)
        }
    }

    /// Focus a specific view
    func focus(_ view: NSView) {
        guard let window = view.window else { return }
        window.makeFirstResponder(view)
    }

    /// Focus the first content view (sorted by screen position - top to bottom)
    func focusFirst() {
        let views = validContentViews()
        if let first = views.first {
            first.window?.makeFirstResponder(first)
            currentContentIndex = 0
        }
    }

    /// Focus the last content view (bottommost on screen)
    func focusLast() {
        let views = validContentViews()
        if let last = views.last {
            last.window?.makeFirstResponder(last)
            currentContentIndex = views.count - 1
        }
    }

    // MARK: - Private

    private func sortByPosition(_ view1: NSView, _ view2: NSView) -> Bool {
        // Sort by y position (higher y = higher on screen in window coordinates)
        let y1 = view1.convert(view1.bounds.origin, to: nil).y
        let y2 = view2.convert(view2.bounds.origin, to: nil).y
        return y1 > y2  // Higher y first (top of window)
    }

    /// Which of `views` currently holds the caret, or -1.
    ///
    /// The subtlety is text fields. While one is being edited the window's
    /// first responder is the shared *field editor*, not the `NSTextField`
    /// that registered here — so a straight identity test answered "focus is
    /// nowhere" for a caret plainly sitting in a field. Tab and the arrows
    /// then fell to the -1 branch and jumped to the first or last control
    /// instead of the neighbour, which is what left typing in an Other field
    /// feeling like no man's land: every way out teleported.
    ///
    /// The field editor is installed inside the control it edits, so walking
    /// up the view tree finds that control. Doing the walk for every responder
    /// also covers any other focusable subview a registered view may contain.
    private func findCurrentIndex(in views: [NSView]) -> Int {
        let window = views.first(where: { $0.window != nil })?.window
        guard let responder = window?.firstResponder else { return -1 }

        var node = responder as? NSView
        while let current = node {
            if let index = views.firstIndex(where: { $0 === current }) { return index }
            node = current.superview
        }

        // Belt and braces: a field editor that is not in the field's subtree
        // still names its client as its delegate.
        if let editor = responder as? NSText,
           let client = editor.delegate as? NSView,
           let index = views.firstIndex(where: { $0 === client }) {
            return index
        }
        return -1
    }

    private func updateCurrentContentIndex() {
        currentContentIndex = findCurrentIndex(in: validContentViews())
    }
}

