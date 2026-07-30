import AppKit

// Layout probe.
//
// The screenshot harness could always *show* a clipped dialog; it could never
// say so. A human had to read a contact sheet of eighty states and notice.
// These two probes turn a rendered state into facts a script can fail on.
//
// The geometry probe asks the real view tree what it wanted to be. SwiftUI
// hands `fittingSize` back as the size the content actually needs, and the
// hosting view's frame is the size it was given; a positive difference is
// content that exists and has nowhere to go. That one number is the fact
// behind most of what reads as "the window is clipping" — the frame arms get
// pushed past the edge, the footer ends up under the note pane, the last
// option row is half a row.
//
// The pixel probe exists because the geometry probe is half blind. SwiftUI
// draws `Text` into the hosting view's own layer rather than into child
// NSViews, so no amount of tree walking finds a cut glyph or two elements
// drawn on top of each other. Working from the captured bitmap sees whatever
// was actually drawn, at the cost of having to be told what "empty" looks
// like — which is why it derives the panel background from the image instead
// of hardcoding a skin's colour.

// MARK: - Geometry

/// The hosting view is the only child `createAutoSizedWindow` adds to the
/// background view, but it is generic over its root view, so it can only be
/// recognised by name.
func findHostingView(in window: NSWindow) -> NSView? {
    guard let content = window.contentView else { return nil }
    var queue = content.subviews
    while !queue.isEmpty {
        let view = queue.removeFirst()
        if String(describing: type(of: view)).hasPrefix("NSHostingView") { return view }
        queue.append(contentsOf: view.subviews)
    }
    return nil
}

private func rectArray(_ r: CGRect) -> [Double] {
    [Double(r.origin.x), Double(r.origin.y), Double(r.size.width), Double(r.size.height)]
}

/// How much room a text widget's content actually needs at the width it was
/// given. `intrinsicContentSize` is not enough on its own: an `NSTextView`
/// reports no intrinsic metric at all, and a field that has been told to
/// truncate reports the truncated size rather than the real one.
func textSize(of view: NSView, width: CGFloat) -> CGSize? {
    guard width > 1 else { return nil }

    if let textView = view as? NSTextView {
        // TextKit 1 is still what `NSTextView` uses unless the view opts in to
        // TextKit 2, and it is the only one that can answer this directly.
        if let manager = textView.layoutManager, let container = textView.textContainer {
            manager.ensureLayout(for: container)
            let used = manager.usedRect(for: container)
            return CGSize(width: used.width, height: used.height)
        }
        let text = textView.attributedString()
        guard text.length > 0 else { return nil }
        let box = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        return CGSize(width: ceil(box.width), height: ceil(box.height))
    }

    if let field = view as? NSTextField, let cell = field.cell {
        let size = cell.cellSize(forBounds: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    return nil
}

/// Walks the AppKit half of the tree. Only the `NSViewRepresentable` widgets
/// live here — `FocusableButton`, `FocusableTextField`, `FocusableChoiceCard`
/// and the text views inside them — but those are exactly the ones that can
/// report an intrinsic size, so they are the ones that can prove a label was
/// truncated rather than merely look like it.
func walkViews(_ view: NSView, root: NSView, depth: Int = 0, scrolled: Bool = false, into out: inout [[String: Any]]) {
    let frame = view.convert(view.bounds, to: root)
    let name = String(describing: type(of: view))

    // A row scrolled out of a list is *supposed* to sit outside the window and
    // to share coordinates with whatever is scrolled past it, so neither the
    // escape rule nor the overlap rule can say anything true about it. A
    // control the layout put outside the window is the opposite — exactly the
    // bug worth reporting. Telling them apart is the whole difficulty.
    //
    // "Has a scroll view somewhere above it" is too blunt: an `NSTextView` is
    // normally built inside one, so that test silently excused the note editor
    // and with it the pane-over-footer collision this harness exists to catch.
    // Asking the `NSClipView` for its visible rect does not work either —
    // SwiftUI clips at the layer and leaves the clip view as tall as its
    // content, so it reports everything as visible.
    //
    // What does separate them is the scroll view's own frame. A list SwiftUI
    // cannot fit is laid out at full content height and hangs outside the
    // surface; a scroller that fits sits entirely inside it. So a subtree is
    // treated as scrolled away only when its scroll view is itself outside.
    var inScrolledRegion = scrolled
    if !scrolled, view is NSScrollView {
        inScrolledRegion = !root.bounds.insetBy(dx: -0.5, dy: -0.5).contains(frame)
    }
    let scrolledAway = scrolled

    // The hosting view itself and the plain container views carry no signal;
    // recording them buries the widgets that do.
    let interesting = !name.hasPrefix("NSHostingView")
        && !name.hasPrefix("_NSHostingView")
        && frame.width > 0 && frame.height > 0

    if interesting {
        var entry: [String: Any] = ["class": name, "depth": depth, "frame": rectArray(frame)]

        let intrinsic = view.intrinsicContentSize
        // `NSView.noIntrinsicMetric` is -1; a widget that declines to have an
        // opinion has nothing to compare against.
        if intrinsic.width > 0 || intrinsic.height > 0 {
            entry["intrinsic"] = [Double(intrinsic.width), Double(intrinsic.height)]
            if intrinsic.width > frame.width + 0.5 { entry["truncatedWidth"] = true }
            if intrinsic.height > frame.height + 0.5 { entry["truncatedHeight"] = true }
        }

        // What the text actually needs, versus the box it was given. This is
        // the one measurement that catches a fixed-height region holding
        // variable-length content — a note editor pinned to 62 units, a
        // description laid into a row sized for one line — which is most of
        // what "long text breaks the dialog" turns out to mean.
        if let needed = textSize(of: view, width: frame.width) {
            entry["textSize"] = [Double(needed.width), Double(needed.height)]
            if needed.height > frame.height + 1 { entry["textOverflowHeight"] = Double(needed.height - frame.height) }
            if needed.width > frame.width + 1 { entry["textOverflowWidth"] = Double(needed.width - frame.width) }
        }

        // Interactive elements are the ones whose overlap is unambiguously a
        // bug: two things a person can click cannot occupy the same pixels.
        // Every skin routes focus through an `NSView`, so this is the one
        // structural fact that survives a reskin.
        //
        // SwiftUI mounts each representable inside an `AppKitPlatformViewHost`
        // with an identical frame. Counting both halves would pair every
        // widget with its own wrapper, so only the inner view is marked.
        let isWrapper = name.hasPrefix("AppKitPlatformViewHost")
        if !isWrapper, name.contains("Target") || name.contains("Focusable")
            || view is NSButton || view is NSTextView || view is NSTextField {
            entry["interactive"] = true
        }
        // A half-point of overhang is layout rounding, not a bug.
        let bounds = root.bounds.insetBy(dx: -0.5, dy: -0.5)
        if !bounds.contains(frame) { entry["escapes"] = true }
        if scrolledAway { entry["clipped"] = true }

        out.append(entry)
    }

    for sub in view.subviews {
        walkViews(sub, root: root, depth: depth + 1, scrolled: inScrolledRegion, into: &out)
    }
}

func probeGeometry(_ window: NSWindow) -> [String: Any] {
    var report: [String: Any] = [:]
    report["window"] = rectArray(window.frame)

    guard let content = window.contentView else { return report }
    report["content"] = [Double(content.bounds.width), Double(content.bounds.height)]

    guard let hosting = findHostingView(in: window) else { return report }
    let frame = hosting.frame
    let fitting = hosting.fittingSize
    report["hostingFrame"] = rectArray(frame)
    report["fitting"] = [Double(fitting.width), Double(fitting.height)]

    // The number the whole harness turns on: what the content asked for minus
    // what it was given. Positive means clipped.
    report["overflowWidth"] = Double(fitting.width - frame.width)
    report["overflowHeight"] = Double(fitting.height - frame.height)

    // A window at the height cap is not itself a bug — a twenty-option list is
    // supposed to stop growing and scroll — but it changes how overflow reads,
    // so the checker needs to know.
    let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
    report["screenHeight"] = Double(screenHeight)
    report["atHeightCap"] = window.frame.height >= screenHeight * 0.85 - 1

    var views: [[String: Any]] = []
    walkViews(hosting, root: hosting, into: &views)
    report["views"] = views

    return report
}

// MARK: - Pixels

/// Bounding box of everything that is not fully transparent — in practice the
/// dialog's own background panel, since the window is borderless over a clear
/// background. Its inset from the capture edge is the window padding, and a
/// zero inset means the panel has grown into the space its shadow needs.
private struct Box {
    var minX = Int.max, minY = Int.max, maxX = Int.min, maxY = Int.min
    var isEmpty: Bool { minX > maxX }
    mutating func add(_ x: Int, _ y: Int) {
        if x < minX { minX = x }
        if x > maxX { maxX = x }
        if y < minY { minY = y }
        if y > maxY { maxY = y }
    }
    var json: [Int] { isEmpty ? [] : [minX, minY, maxX - minX + 1, maxY - minY + 1] }
}

/// Scale-independent thresholds are expressed in device pixels; the capture is
/// always 2x, which the caller confirms via `scale`.
private let alphaFloor = 8
private let inkDistance = 40   // summed channel difference from the panel colour

func probePixels(_ rep: NSBitmapImageRep, scale: Int) -> [String: Any] {
    guard let data = rep.bitmapData, rep.samplesPerPixel == 4, rep.bitsPerSample == 8 else {
        return ["error": "unsupported bitmap format"]
    }
    let width = rep.pixelsWide, height = rep.pixelsHigh
    let rowBytes = rep.bytesPerRow, pixelBytes = rep.bitsPerPixel / 8

    var panel = Box()
    // Quantised colour histogram. The panel background is by a wide margin the
    // most common colour inside the dialog, and quantising to 32 levels per
    // channel keeps gradient banding from splitting it across buckets.
    var histogram: [Int: Int] = [:]

    for y in 0..<height {
        let row = data + y * rowBytes
        for x in 0..<width {
            let p = row + x * pixelBytes
            guard Int(p[3]) > alphaFloor else { continue }
            panel.add(x, y)
            let key = (Int(p[0]) >> 3) << 10 | (Int(p[1]) >> 3) << 5 | (Int(p[2]) >> 3)
            histogram[key, default: 0] += 1
        }
    }

    var report: [String: Any] = [
        "size": [width, height],
        "scale": scale,
        "panel": panel.json,
    ]
    guard !panel.isEmpty, let (modal, modalCount) = histogram.max(by: { $0.value < $1.value }) else {
        report["error"] = "no opaque pixels"
        return report
    }

    let bgR = ((modal >> 10) & 31) << 3, bgG = ((modal >> 5) & 31) << 3, bgB = (modal & 31) << 3
    report["background"] = [bgR, bgG, bgB]
    report["backgroundShare"] = Double(modalCount) / Double(max(panel.json[2] * panel.json[3], 1))

    // Ink: anything inside the panel that is not the panel. Glyphs, rules,
    // borders, the frame arms — everything a person would call content.
    var ink = Box()
    // Per-edge counts in the outermost band of the panel. Content is supposed
    // to keep clear of the panel border; ink in the band is either a frame arm
    // that has been pushed into the edge or a glyph that has been cut by it.
    let band = 2 * scale
    var bandCount = [0, 0, 0, 0]   // top, right, bottom, left

    for y in panel.minY...panel.maxY {
        let row = data + y * rowBytes
        for x in panel.minX...panel.maxX {
            let p = row + x * pixelBytes
            guard Int(p[3]) > alphaFloor else { continue }
            let distance = abs(Int(p[0]) - bgR) + abs(Int(p[1]) - bgG) + abs(Int(p[2]) - bgB)
            guard distance > inkDistance else { continue }
            ink.add(x, y)
            if y - panel.minY < band { bandCount[0] += 1 }
            if panel.maxX - x < band { bandCount[1] += 1 }
            if panel.maxY - y < band { bandCount[2] += 1 }
            if x - panel.minX < band { bandCount[3] += 1 }
        }
    }

    report["ink"] = ink.json
    report["edgeInk"] = ["top": bandCount[0], "right": bandCount[1], "bottom": bandCount[2], "left": bandCount[3]]
    if !ink.isEmpty {
        report["inkInset"] = [
            "top": ink.minY - panel.minY,
            "right": panel.maxX - ink.maxX,
            "bottom": panel.maxY - ink.maxY,
            "left": ink.minX - panel.minX,
        ]
    }
    report["panelInset"] = [
        "top": panel.minY,
        "right": width - 1 - panel.maxX,
        "bottom": height - 1 - panel.maxY,
        "left": panel.minX,
    ]
    return report
}

// MARK: - Emit

func writeReport(_ report: [String: Any], to path: String) {
    guard let data = try? JSONSerialization.data(
        withJSONObject: report, options: [.prettyPrinted, .sortedKeys]
    ) else { return }
    try? data.write(to: URL(fileURLWithPath: path))
}
