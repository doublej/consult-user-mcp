import AppKit

// MARK: - Focus Manager

/// Centralized focus management for NSViewRepresentable views in SwiftUI
final class FocusManager {
    static let shared = FocusManager()

    private var contentViews: [NSView] = []  // Options, text fields - navigable with arrows
    private var buttonViews: [NSView] = []   // Buttons - only reachable via Tab
    private var currentContentIndex: Int = -1

    private init() {}

    /// Register a content view (option cards, text fields) - navigable with arrow keys
    func registerContent(_ view: NSView) {
        if !contentViews.contains(where: { $0 === view }) {
            contentViews.append(view)
        }
    }

    /// Register a button view - only reachable via Tab, not arrows
    func registerButton(_ view: NSView) {
        if !buttonViews.contains(where: { $0 === view }) {
            buttonViews.append(view)
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
        updateCurrentContentIndex()
    }

    /// Clear all registered views (call when dialog closes)
    func reset() {
        contentViews.removeAll()
        buttonViews.removeAll()
        currentContentIndex = -1
    }

    /// Move focus to next content view (arrow keys) - excludes buttons
    func focusNextContent() {
        let validViews = contentViews
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        guard !validViews.isEmpty else { return }

        updateCurrentContentIndex()

        let nextIndex = (currentContentIndex + 1) % validViews.count
        if let view = validViews[safe: nextIndex] {
            view.window?.makeFirstResponder(view)
            currentContentIndex = nextIndex
        }
    }

    /// Move focus to previous content view (arrow keys) - excludes buttons
    func focusPreviousContent() {
        let validViews = contentViews
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        guard !validViews.isEmpty else { return }

        updateCurrentContentIndex()

        let prevIndex = currentContentIndex <= 0 ? validViews.count - 1 : currentContentIndex - 1
        if let view = validViews[safe: prevIndex] {
            view.window?.makeFirstResponder(view)
            currentContentIndex = prevIndex
        }
    }

    /// Move focus to next view (Tab) - includes all views
    func focusNext() {
        let allViews = (contentViews + buttonViews)
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        guard !allViews.isEmpty else { return }

        let currentIndex = findCurrentIndex(in: allViews)
        let nextIndex = (currentIndex + 1) % allViews.count
        if let view = allViews[safe: nextIndex] {
            view.window?.makeFirstResponder(view)
        }
    }

    /// Move focus to previous view (Shift+Tab) - includes all views
    func focusPrevious() {
        let allViews = (contentViews + buttonViews)
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        guard !allViews.isEmpty else { return }

        let currentIndex = findCurrentIndex(in: allViews)
        let prevIndex = currentIndex <= 0 ? allViews.count - 1 : currentIndex - 1
        if let view = allViews[safe: prevIndex] {
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
        let validViews = contentViews
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        if let first = validViews.first {
            first.window?.makeFirstResponder(first)
            currentContentIndex = 0
        }
    }

    /// Focus the last content view (bottommost on screen)
    func focusLast() {
        let validViews = contentViews
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        if let last = validViews.last {
            last.window?.makeFirstResponder(last)
            currentContentIndex = validViews.count - 1
        }
    }

    // MARK: - Private

    private func sortByPosition(_ view1: NSView, _ view2: NSView) -> Bool {
        // Sort by y position (higher y = higher on screen in window coordinates)
        let y1 = view1.convert(view1.bounds.origin, to: nil).y
        let y2 = view2.convert(view2.bounds.origin, to: nil).y
        return y1 > y2  // Higher y first (top of window)
    }

    private func findCurrentIndex(in views: [NSView]) -> Int {
        if let window = views.first?.window,
           let firstResponder = window.firstResponder as? NSView,
           let index = views.firstIndex(where: { $0 === firstResponder }) {
            return index
        }
        return -1
    }

    private func updateCurrentContentIndex() {
        let validViews = contentViews
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted(by: sortByPosition)
        currentContentIndex = findCurrentIndex(in: validViews)
    }
}

