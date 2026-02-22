# SwiftUI/Swift Code Review: consult-user-mcp

**Project:** Consult User MCP (macOS dialog CLI + tray app)
**Review Date:** February 2026
**Scope:** dialog-cli and macos-app SwiftUI/AppKit code
**Modified File:** `dialog-cli/Sources/DialogCLI/Components/Buttons.swift`

---

## Executive Summary

The codebase demonstrates **solid architectural patterns** with clear separation of concerns and well-thought-out focus/keyboard management. Code quality is **generally strong** with good naming conventions and adherence to SwiftUI best practices. However, there are **moderate opportunities for improvement** around memory management, type safety, and component organization.

**Overall Assessment:** Production-ready with recommendations for refinement

---

## 1. Code Quality & Style Consistency

### Strengths
- **Consistent formatting and structure** across dialog-cli components
- **Clear MARK comments** for section organization (FocusableButton, FocusableTextFieldView, etc.)
- **Proper use of property observers** (didSet in ChoiceCard.swift:36-37)
- **Good naming conventions**: verb-based functions (focusNext, syncCooldown, registerButton)
- **SwiftUI best practices**: appropriate use of @State, @Binding, @Published, ObservableObject

### Areas for Improvement

#### 1.1 Buttons.swift - Repetitive Parameter Assignment (Lines 23-42)
**Issue:** Unnecessary repetition in NSViewRepresentable lifecycle

```swift
// Current approach (Lines 23-32 and 34-40)
func makeNSView(context: Context) -> FocusableButtonView {
    let view = FocusableButtonView()
    view.title = title
    view.isPrimary = isPrimary
    view.isDestructive = isDestructive
    view.isDisabled = isDisabled
    view.showReturnHint = showReturnHint
    view.onClick = action
    return view
}

func updateNSView(_ nsView: FocusableButtonView, context: Context) {
    nsView.title = title
    // ... 7 repeated assignments
}
```

**Recommendation:** Extract into helper method:
```swift
private func updateView(_ view: FocusableButtonView) {
    view.title = title
    view.isPrimary = isPrimary
    view.isDestructive = isDestructive
    view.isDisabled = isDisabled
    view.showReturnHint = showReturnHint
    view.onClick = action
}
```

#### 1.2 FocusableTextFieldView - Inconsistent Initialization Path (Lines 415-425)
**Issue:** Two init methods with subtle differences in setup order

```swift
init(isSecure: Bool = false) {
    textField = isSecure ? NSSecureTextField() : NSTextField()
    super.init(frame: .zero)
    setupTextField()  // Called here
}

override init(frame frameRect: NSRect) {
    textField = NSTextField()
    super.init(frame: frameRect)
    setupTextField()  // Called here too
}
```

**Risk:** If one path is used through NSViewRepresentable lifecycle and another through direct instantiation, setupTextField() may be called twice or inconsistently.

**Recommendation:** Ensure single initialization path:
```swift
init(isSecure: Bool = false, frame: NSRect = .zero) {
    textField = isSecure ? NSSecureTextField() : NSTextField()
    super.init(frame: frame)
    setupTextField()
}

required init?(coder: NSCoder) {
    fatalError("Use init(isSecure:frame:)")
}

override init(frame frameRect: NSRect) {
    self.init(isSecure: false, frame: frameRect)
}
```

#### 1.3 Theme Naming Inconsistency (Theme.swift:77-78)
**Issue:** Confusing color naming in SunsetTheme

```swift
let accentBlue = NSColor(red: 1.0, green: 0.55, blue: 0.25, alpha: 1.0)  // Orange as primary
let accentBlueDark = NSColor(red: 0.90, green: 0.45, blue: 0.15, alpha: 1.0)
```

**Problem:** `accentBlue` is actually orange; comment indicates awareness but naming is misleading. Used throughout Buttons.swift (lines 240, 242, 294, etc.).

**Recommendation:** Rename for clarity:
```swift
let accentOrange = NSColor(...)  // primary accent
let accentOrangeDark = NSColor(...)
```

---

## 2. UI/UX Patterns & Best Practices

### Strengths
- **Excellent focus management** via FocusManager (Services/FocusManager.swift)
  - Separates content navigation (arrow keys) from button navigation (Tab)
  - Maintains currentContentIndex for proper cycling
  - Caches sorted views for performance

- **Keyboard accessibility** well-implemented
  - ESC → cancel
  - RETURN → submit
  - SPACE → toggle selection
  - ARROW keys → navigate content
  - Proper KeyboardHints display (KeyboardHints.swift)

- **State management clarity**
  - CooldownManager properly handles cooldown lifecycle (Services/CooldownManager.swift)
  - Notification-based updates (cooldownDidChange) allow reactive UI updates
  - Progress tracking from 0-1 for visual feedback

- **Visual feedback consistency**
  - Hover/pressed states properly distinguished in buttons and choice cards
  - Focus ring support via drawFocusRingMask() (Buttons.swift:76-79, ChoiceCard.swift:99-102)
  - Disabled state styling consistent (opacity, color muting)

### Issues & Gaps

#### 2.1 Button Cooldown Visual Feedback (Buttons.swift:280-297)
**Issue:** Cooldown bar color hardcoded to white/blue, doesn't adapt to button state

```swift
let barColor = isPrimary ? NSColor.white.withAlphaComponent(0.7) : Theme.accentBlue.withAlphaComponent(0.6)
```

**Problem:** On hover/pressed, the bar may have poor contrast. Destructive button cooldown bar uses blue instead of red.

**Recommendation:** Adapt bar color to button type:
```swift
let barColor = isDestructive
    ? Theme.accentRed.withAlphaComponent(0.7)
    : (isPrimary ? NSColor.white.withAlphaComponent(0.7) : Theme.accentBlue.withAlphaComponent(0.6))
```

#### 2.2 ChoiceCard Size Calculation Edge Case (ChoiceCard.swift:189)
**Issue:** Fallback width of 300 when bounds.width is 0 may not reflect actual layout

```swift
let width = bounds.width > 0 ? bounds.width : 300
```

**Risk:** During initial layout, intrinsicContentSize is calculated with 300pt width, but actual width might differ, causing relayout and potential jank.

**Recommendation:** Use reasonable default or lazy initialization:
```swift
override var intrinsicContentSize: NSSize {
    guard bounds.width > 0 else {
        return NSSize(width: NSView.noIntrinsicMetric, height: 48)  // Let layout system decide
    }
    // ... rest of calculation
}
```

#### 2.3 Tooltip Support Missing (DialogComponents.swift:31)
**Issue:** ProjectBadge uses `.help()` modifier for tooltip, but other interactive elements (buttons, cards) don't

**Recommendation:** Add accessibility labels to FocusableButtonView and FocusableChoiceCardView via didSet triggers that update view accessibility properties.

---

## 3. Bugs & Potential Issues

### Critical

#### 3.1 Memory Leak Risk in FocusableButtonView (Buttons.swift:59-62, 120-128)
**Issue:** cooldownObserver stored as NSObjectProtocol, unclear when removed

```swift
private var cooldownObserver: NSObjectProtocol?

private func startObservingCooldown() {
    guard cooldownObserver == nil else { return }
    cooldownObserver = NotificationCenter.default.addObserver(
        forName: .cooldownDidChange,
        // ...
    ) { [weak self] _ in
        self?.syncCooldown()
    }
}
```

**Risk:** If stopObservingCooldown() isn't called (e.g., window closes unexpectedly), observer persists. The closure captures [weak self], which is good, but the observer token should be explicitly managed.

**Recommendation:** Use AnyCancellable pattern:
```swift
private var cooldownObserver: NSObjectProtocol?

override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if window != nil {
        FocusManager.shared.registerButton(self)
        startObservingCooldown()
        syncCooldown()
    } else {
        cleanup()  // Centralize cleanup
    }
}

private func cleanup() {
    stopObservingCooldown()
    stopCooldownUpdates()
    FocusManager.shared.unregister(self)
    cooldownProgress = 1
}

deinit {
    cleanup()
}
```

#### 3.2 DispatchSourceTimer Resource Leak (Buttons.swift:149-164)
**Issue:** Timer is created every time cooldown starts, potential for orphaned timers

```swift
private func startCooldownUpdates() {
    guard cooldownTimer == nil else { return }
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: 1.0 / 60.0)
    timer.setEventHandler { [weak self] in
        // ... updates
        if progress >= 1 {
            self?.stopCooldownUpdates()
        }
    }
    timer.resume()
    cooldownTimer = timer
}
```

**Risk:** If stopCooldownUpdates() not called and new timer starts before cleanup, old timer continues running in background.

**Better:** Explicitly cancel old timer:
```swift
private func startCooldownUpdates() {
    cooldownTimer?.cancel()  // Cancel any existing timer first
    let timer = DispatchSource.makeTimerSource(queue: .main)
    // ... rest
}
```

### Moderate

#### 3.3 FocusableTextFieldView Focus State Tracking (Buttons.swift:513)
**Issue:** Focus detection compares responder identity, fragile

```swift
let isFocused = window?.firstResponder == textField || window?.firstResponder == textField.currentEditor()
```

**Risk:** fieldEditor() can change, identity comparison may fail after text editing transitions.

**Recommendation:** Add private property to track focus state:
```swift
private var isFocused = false

override func becomeFirstResponder() -> Bool {
    isFocused = true
    // ...
    return true
}

override func resignFirstResponder() -> Bool {
    isFocused = false
    return true
}

override func draw(_ dirtyRect: NSRect) {
    let borderColor = isFocused ? Theme.accentBlue : Theme.border
    // ...
}
```

#### 3.4 Thread Safety in FocusManager (Services/FocusManager.swift)
**Issue:** contentViews and buttonViews arrays are modified from main thread, but no explicit thread checking

```swift
private var contentViews: [NSView] = []
private var buttonViews: [NSView] = []

func registerContent(_ view: NSView) {
    if !contentViews.contains(where: { $0 === view }) {
        contentViews.append(view)
        invalidateCache()
    }
}
```

**Risk:** If called from background thread (unlikely but possible), could cause crashes.

**Recommendation:** Add assertion:
```swift
func registerContent(_ view: NSView) {
    assert(Thread.isMainThread, "FocusManager must be accessed from main thread")
    // ...
}
```

### Minor

#### 3.5 Safe Array Access Pattern (ChoiceCard.swift:68)
**Good pattern used:** Extension method `[safe: index]` prevents out-of-bounds crashes

```swift
subtitle: descriptions?[safe: index],
```

**Should be applied everywhere:** Ensure this safe access pattern is used in FocusManager and other array accesses. ✓ Already done in FocusManager:87, 101, 114, 126.

---

## 4. Component Structure & Organization

### Architecture Overview

```
dialog-cli/Sources/DialogCLI/
├── Components/
│   ├── Buttons.swift               # FocusableButton + FocusableTextField
│   ├── ChoiceCard.swift            # FocusableChoiceCard
│   ├── DialogComponents.swift      # ProjectBadge, MarkdownText, etc.
│   └── DialogToolbar.swift
├── Dialogs/
│   ├── ChooseDialog.swift          # Uses FocusableChoiceCard
│   ├── TextInputDialog.swift       # Uses FocusableTextField
│   ├── ConfirmDialog.swift
│   └── [4 more dialog types]
├── Services/
│   ├── FocusManager.swift          # Navigation state machine
│   ├── CooldownManager.swift       # Cooldown lifecycle
│   ├── DialogManager.swift         # Entry point router
│   └── [6 more service files]
└── Theme/
    └── Theme.swift                 # ThemeProtocol, MidnightTheme, SunsetTheme
```

### Strengths
- **Clear separation:** Components, Dialogs, Services, Theme are well-delineated
- **Single responsibility:** Each component handles one concern (button, text field, choice card)
- **Service pattern:** FocusManager, CooldownManager are singletons managing global state
- **Dependency injection:** Dialog components receive callbacks rather than holding state

### Organization Issues

#### 4.1 Components Responsibility Creep
**Issue:** FocusableButtonView (Buttons.swift:47) is a 290-line class doing too much:
- Rendering (draw() method, 107 lines)
- Focus management (viewDidMoveToWindow, acceptsFirstResponder)
- Cooldown tracking (3 private methods)
- Tracking areas (updateTrackingAreas, mouse events)
- Keyboard handling (keyDown)

**Recommendation:** Extract drawing logic:
```swift
// New file: ButtonRenderer.swift
struct ButtonRenderer {
    func draw(in rect: NSRect, title: String, isPrimary: Bool, ...)
}
```

#### 4.2 FocusableTextFieldView Wrapping Overhead
**Issue:** NSTextField is wrapped in NSView, adding complexity

```swift
class FocusableTextFieldView: NSView, NSTextFieldDelegate {
    private let textField: NSTextField
```

**Alternative:** Consider if NSViewRepresentable can directly wrap NSTextField with custom focus handling, reducing one level of indirection.

---

## 5. Accessibility Considerations

### Strengths
- **VoiceOver support via accessibility labels** (ChooseDialog.swift:60-62)
- **Keyboard-only navigation** fully supported
- **Visual focus rings** properly drawn (drawFocusRingMask)
- **Clear button hints** (Space, Return, Arrow keys)

### Gaps

#### 5.1 Missing Accessibility for Interactive Views
**Issue:** FocusableButtonView and FocusableChoiceCardView don't expose accessibility properties

```swift
// Current: no accessibility properties
class FocusableButtonView: NSView {
    // ...
}
```

**Recommendation:** Add accessibility support:
```swift
class FocusableButtonView: NSView {
    override func makeAccessibilityElement() -> Any? {
        return NSAccessibilityButton(role: .button, subrole: nil, isSelected: false)
    }

    override var accessibilityLabel: String? {
        get { title }
        set { }
    }

    override var accessibilityRoleDescription: String? {
        return isDestructive ? "Destructive Button" : "Button"
    }
}
```

#### 5.2 No Accessibility for Dynamic Cooldown State
**Issue:** When button enters cooldown, accessibility status doesn't update

**Recommendation:** Post accessibility notifications:
```swift
private func syncCooldown() {
    if isCoolingDown {
        NSAccessibility.post(element: self, notification: .announceRequested)
    }
}
```

#### 5.3 ChoiceCard Indicator Not Described
**Issue:** Checkbox/radio button drawn manually but not announced to VoiceOver

```swift
// Lines 262-298: draws checkbox/radio, but no accessibility info
if isMultiSelect {
    // Checkbox rendering
} else {
    // Radio button rendering
}
```

**Recommendation:** Override accessibility methods:
```swift
override var accessibilityElement: Any? {
    let element = NSAccessibilityChoice(role: isMultiSelect ? .checkBox : .radioButton)
    element?.isSelected = isSelected
    return element
}
```

---

## 6. Performance Notes

### Strengths
- **View caching in FocusManager** (validContentViews, validAllViews with cached results)
- **Text size caching in ChoiceCard** (cachedTitleSize, cachedSubtitleSize, invalidateCachedSizes)
- **60 FPS cooldown timer** (Buttons.swift:152) appropriate for smooth visual feedback
- **Lazy tracking area updates** (updateTrackingAreas called on layout changes)

### Potential Bottlenecks

#### 6.1 Markdown Parsing Overhead (DialogComponents.swift)
**Status:** RESOLVED (commit 8718db6 — regex patterns deduplicated into static constants)

#### 6.2 Bounds Width Calculation in ChoiceCard (ChoiceCard.swift:60-86)
**Issue:** calculateSizes() does string bounds measurement every draw

```swift
cachedTitleSize = (title as NSString).boundingRect(
    with: NSSize(width: contentWidth, height: .greatestFiniteMagnitude),
    options: [.usesLineFragmentOrigin],
    attributes: titleAttrs
).size
```

**Impact:** With 50+ choices, this could impact scroll performance. ✓ Mitigation: Caching via invalidateCachedSizes() is good.

**Verify:** Check if invalidateCachedSizes() is called appropriately when title changes (it is, via didSet:36).

---

## 7. Security Assumptions & Trust Boundaries

### Input Validation
- **User input in TextInputDialog** passed directly to JSON response, no sanitization
  - Acceptable for dialog text (escaped by JSON encoder)
  - Consider: very long text could cause performance issues (no length limit visible)

- **Choice indices** validated at response time (ChooseDialog.swift:123)
  - Good: checks selectedIndices.isEmpty before completion

### Keyboard Input Handling
- **KeyCode enum** (Utilities/KeyCode.swift) uses hardcoded UInt16 values
  - Assumes macOS key codes (valid for Swift on macOS)
  - No input injection vulnerability

### Theme & Settings
- **UserSettings.load()** (CooldownManager.swift:20) assumes valid settings file
  - Consider: what if JSON is malformed? (Likely handled by UserSettings implementation)

---

## 8. Feature List

**dialog-cli Component Features:**
- FocusableButton: Primary/secondary/destructive states, cooldown animation, keyboard activation
- FocusableTextField: Placeholder support, secure input, editor styling, focus ring
- FocusableChoiceCard: Single/multi-select, checkbox/radio indicators, custom sizing
- Focus management: Arrow-key navigation (content), Tab navigation (all views), cycling
- Cooldown protection: Progress bar, configurable duration, visual feedback
- Theme support: Midnight (dark), Sunset (warm) with consistent color palettes
- Markdown rendering: Links, bold, italic text in dialogs
- Accessibility: VoiceOver labels (partial), keyboard-only navigation, focus rings

**macos-app Features:**
- Settings window: 8+ tabs for configuration
- History tracking: Dialog interactions logged
- Update management: Auto-check, prerelease support, reminder scheduling
- Projects view: Folder shortcuts, recent projects
- Installation guides: Claude.md, MCP setup wizards
- Snooze management: Timed suppression of dialogs

---

## 9. Assumptions & Unknowns

| Assumption | Risk | Verification |
|-----------|------|--------------|
| Window always exists during render | Medium | add nil checks in draw() |
| Theme colors remain constant during session | Low | Colors loaded at app start ✓ |
| Main thread execution guaranteed | Medium | Add `assert(Thread.isMainThread)` |
| KeyCode values match macOS 10.15+ | Low | Used in production, likely tested |
| NSTextField supports custom focus styling | Medium | Test on Big Sur+ |
| NotificationCenter delivery is reliable | Low | Core framework, well-tested |
| CooldownManager progress is monotonic | Low | Math.min/max bounded ✓ |
| Array safe subscript extension exists | High | Verify Extension.swift defines it |

---

## 10. Recommendations Summary

### High Priority
1. **Fix timer leak risk** (3.2): Ensure old timer cancelled before new one starts
2. **Clarify color naming** (1.3): Rename accentBlue to accentOrange in SunsetTheme
3. **Extract drawing logic** (4.1): Reduce FocusableButtonView from 290 to ~150 lines
4. **Add thread assertions** (3.4): FocusManager methods should verify main thread

### Medium Priority
5. **Improve focus tracking** (3.3): Use private isFocused flag instead of responder comparison
6. **Cache markdown regex** (6.1): Avoid recompiling patterns on every render
7. **Add accessibility support** (5.1-5.3): NSAccessibility roles for button, card, indicators
8. **Unify initialization** (1.2): Single init path for FocusableTextFieldView

### Low Priority
9. **Extract repeated assignments** (1.1): DRY up NSViewRepresentable setup
10. **Improve cooldown bar color** (2.1): Adapt to button type (destructive = red)
11. **Fix size calculation fallback** (2.2): Return .noIntrinsicMetric when bounds unknown

---

## Code Snippets: Before/After Examples

### Example 1: DRY Up NSViewRepresentable Setup

**Before:**
```swift
func makeNSView(context: Context) -> FocusableButtonView {
    let view = FocusableButtonView()
    view.title = title
    view.isPrimary = isPrimary
    view.isDestructive = isDestructive
    view.isDisabled = isDisabled
    view.showReturnHint = showReturnHint
    view.onClick = action
    return view
}

func updateNSView(_ nsView: FocusableButtonView, context: Context) {
    nsView.title = title
    nsView.isPrimary = isPrimary
    nsView.isDestructive = isDestructive
    nsView.isDisabled = isDisabled
    nsView.showReturnHint = showReturnHint
    nsView.onClick = action
    nsView.needsDisplay = true
}
```

**After:**
```swift
func makeNSView(context: Context) -> FocusableButtonView {
    let view = FocusableButtonView()
    configure(view)
    return view
}

func updateNSView(_ nsView: FocusableButtonView, context: Context) {
    configure(nsView)
    nsView.needsDisplay = true
}

private func configure(_ view: FocusableButtonView) {
    view.title = title
    view.isPrimary = isPrimary
    view.isDestructive = isDestructive
    view.isDisabled = isDisabled
    view.showReturnHint = showReturnHint
    view.onClick = action
}
```

### Example 2: Fix Timer Leak

**Before:**
```swift
private func startCooldownUpdates() {
    guard cooldownTimer == nil else { return }
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: 1.0 / 60.0)
    // ...
    timer.resume()
    cooldownTimer = timer
}
```

**After:**
```swift
private func startCooldownUpdates() {
    cooldownTimer?.cancel()  // Clean up any existing timer
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: 1.0 / 60.0)
    // ...
    timer.resume()
    cooldownTimer = timer
}
```

### Example 3: Better Focus State Tracking

**Before:**
```swift
override func draw(_ dirtyRect: NSRect) {
    let isFocused = window?.firstResponder == textField || window?.firstResponder == textField.currentEditor()
    let borderColor = isFocused ? Theme.accentBlue : Theme.border
    // ...
}
```

**After:**
```swift
private var isFocused = false

override func becomeFirstResponder() -> Bool {
    isFocused = true
    needsDisplay = true
    return true
}

override func resignFirstResponder() -> Bool {
    isFocused = false
    needsDisplay = true
    return false
}

override func draw(_ dirtyRect: NSRect) {
    let borderColor = isFocused ? Theme.accentBlue : Theme.border
    // ...
}
```

---

## Files Reviewed

**dialog-cli:**
- `/Sources/DialogCLI/Components/Buttons.swift` (547 lines) - Modified
- `/Sources/DialogCLI/Components/ChoiceCard.swift` (300 lines)
- `/Sources/DialogCLI/Components/DialogComponents.swift` (130+ lines)
- `/Sources/DialogCLI/Services/FocusManager.swift` (176 lines)
- `/Sources/DialogCLI/Services/CooldownManager.swift` (83 lines)
- `/Sources/DialogCLI/Utilities/KeyCode.swift` (20 lines)
- `/Sources/DialogCLI/Theme/Theme.swift` (80+ lines)
- `/Sources/DialogCLI/Dialogs/ChooseDialog.swift` (133 lines)
- `/Sources/DialogCLI/Main.swift` (80+ lines)

**macos-app:**
- `/Sources/DialogSettings.swift` (100+ lines)
- `/Sources/AppDelegate.swift` (80+ lines)

---

## Conclusion

The consult-user-mcp codebase demonstrates **professional SwiftUI architecture** with strong patterns around focus management, keyboard accessibility, and state management. The modified Buttons.swift file is well-implemented but has optimization and clarity opportunities.

**Key Strengths:**
- Clear separation of concerns (Components, Services, Dialogs)
- Excellent focus/keyboard navigation (FocusManager, CooldownManager)
- Good performance optimization (view caching, size caching)
- Consistent visual design and theme system

**Key Improvements Needed:**
- Resource cleanup (timer leak potential)
- Naming clarity (accentBlue ≠ orange)
- Code organization (FocusableButtonView too large)
- Accessibility coverage (partial VoiceOver support)

**Recommendation:** Proceed with development; prioritize high-priority recommendations before next release.
