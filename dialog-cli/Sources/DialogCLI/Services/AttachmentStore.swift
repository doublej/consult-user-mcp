import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// One image the person attached to the dialog, already normalised into
/// something an agent can be handed directly.
///
/// `data` is what travels. It is deliberately the *encoded* bytes rather than
/// an `NSImage`: the response is JSON over a pipe, and re-encoding at send
/// time would mean the size limits below were enforced against a picture that
/// no longer exists.
struct DialogAttachment: Identifiable, Equatable {
    let id = UUID()
    let data: Data
    let mimeType: String
    let pixelSize: CGSize
    let name: String
    let thumbnail: NSImage

    static func == (a: DialogAttachment, b: DialogAttachment) -> Bool { a.id == b.id }
}

/// Holds the images attached to the dialog currently on screen.
///
/// A singleton for the same reason `CooldownManager` and `FocusManager` are:
/// one dialog exists per process, the pasteboard handler lives in the key
/// router, the drop handler lives in an `NSView`, and the strip that shows the
/// result lives in SwiftUI. Threading one store through all three buys nothing.
///
/// Main-thread only, like the rest of the CLI's singletons — every caller is a
/// key handler, a drop handler or a SwiftUI body.
final class AttachmentStore: ObservableObject {
    static let shared = AttachmentStore()

    /// Ceilings, all of them about what happens *after* the dialog closes.
    /// These images are embedded in the tool result as image blocks, so every
    /// one of them is spent out of the agent's context window. A person
    /// dropping a folder of screenshots should not silently cost a fortune.
    ///
    /// 1568px is the long edge above which the API downscales anyway, so
    /// sending more is paying to transmit pixels that get thrown away.
    static let maxCount = 8
    static let maxLongEdge: CGFloat = 1568
    static let maxBytesEach = 4 * 1024 * 1024

    @Published private(set) var items: [DialogAttachment] = []
    /// Set when something was rejected, so the strip can say why rather than
    /// appearing to ignore the drop.
    @Published private(set) var lastRejection: String?

    var isEmpty: Bool { items.isEmpty }

    private init() {}

    // MARK: - Taking things in

    /// The pasteboard types worth reading, best first. File URLs come first
    /// because a copied file carries its name and its original encoding, and
    /// both are worth more than the flattened bitmap the same copy also puts
    /// on the pasteboard.
    static var acceptedTypes: [NSPasteboard.PasteboardType] {
        [.fileURL, .png, .tiff]
    }

    @discardableResult
    func addFromPasteboard(_ pasteboard: NSPasteboard = .general) -> Int {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], !urls.isEmpty {
            let images = urls.filter { isImageFile($0) }
            if !images.isEmpty { return add(fileURLs: images) }
        }
        if let data = pasteboard.data(forType: .png) {
            return add(data: data, mimeType: "image/png", name: "Pasted image") ? 1 : 0
        }
        if let data = pasteboard.data(forType: .tiff), let image = NSImage(data: data) {
            return add(image: image, name: "Pasted image") ? 1 : 0
        }
        reject("The clipboard has no image on it")
        return 0
    }

    @discardableResult
    func add(fileURLs: [URL]) -> Int {
        var added = 0
        for url in fileURLs where isImageFile(url) {
            guard let data = try? Data(contentsOf: url) else { continue }
            let mime = mimeType(for: url)
            let name = url.lastPathComponent
            // Formats the agent can take verbatim skip the re-encode, which
            // keeps a photograph a photograph instead of a much larger PNG.
            if mime == "image/png" || mime == "image/jpeg" || mime == "image/gif" || mime == "image/webp" {
                if add(data: data, mimeType: mime, name: name) { added += 1 }
            } else if let image = NSImage(data: data) {
                if add(image: image, name: name) { added += 1 }
            }
        }
        if added == 0 && !fileURLs.isEmpty { reject("No images in that drop") }
        return added
    }

    /// Re-encodes an in-memory image to PNG, downscaling first if it is over
    /// the long-edge ceiling.
    @discardableResult
    func add(image: NSImage, name: String) -> Bool {
        guard let scaled = downscaled(image), let data = png(from: scaled) else {
            reject("Could not read that image")
            return false
        }
        return add(data: data, mimeType: "image/png", name: name)
    }

    @discardableResult
    func add(data: Data, mimeType: String, name: String) -> Bool {
        guard items.count < Self.maxCount else {
            reject("Up to \(Self.maxCount) images")
            return false
        }
        guard let image = NSImage(data: data) else {
            reject("Could not read that image")
            return false
        }

        // Oversized or over-budget images are re-encoded rather than refused:
        // the person's intent is clear and shrinking it is what they wanted.
        var payload = data
        var mime = mimeType
        let size = pixelSize(of: image)
        if size.width > Self.maxLongEdge || size.height > Self.maxLongEdge || payload.count > Self.maxBytesEach {
            guard let scaled = downscaled(image), let reencoded = png(from: scaled) else {
                reject("Could not resize that image")
                return false
            }
            payload = reencoded
            mime = "image/png"
        }
        guard payload.count <= Self.maxBytesEach else {
            reject("That image is too large even after resizing")
            return false
        }

        let final = NSImage(data: payload) ?? image
        items.append(DialogAttachment(
            data: payload,
            mimeType: mime,
            pixelSize: pixelSize(of: final),
            name: name,
            thumbnail: final
        ))
        lastRejection = nil
        notifyLayoutChanged()
        return true
    }

    // MARK: - Taking things out

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        notifyLayoutChanged()
    }

    func clear() {
        guard !items.isEmpty else { return }
        items.removeAll()
        notifyLayoutChanged()
    }

    /// What goes on the wire, in the order they were attached.
    func payloads() -> [AttachmentPayload] {
        items.map {
            AttachmentPayload(
                mimeType: $0.mimeType,
                data: $0.data.base64EncodedString(),
                width: Int($0.pixelSize.width),
                height: Int($0.pixelSize.height),
                name: $0.name
            )
        }
    }

    // MARK: - Test seeding

    /// Fills the strip with generated images so the layout harness can render
    /// it. `DIALOG_TEST_ATTACHMENTS=3` attaches three; `=8` reaches the cap.
    ///
    /// Without this the strip is unreachable from a fixture — it only appears
    /// once something has been pasted or dropped, neither of which a headless
    /// renderer can do. A UI region no test can reach is a UI region that
    /// breaks silently, which is the whole reason the audit exists.
    func seedForTesting(_ spec: String) {
        guard let count = Int(spec), count > 0 else { return }
        // Deliberately varied: a wide screenshot, a tall one and a square icon
        // stress the cell's aspect handling differently, and long filenames
        // are what push the strip's width around.
        let shapes: [(CGSize, String)] = [
            (CGSize(width: 1200, height: 800), "screenshot-of-the-failing-dialog.png"),
            (CGSize(width: 600, height: 1400), "tall-scrolling-capture.png"),
            (CGSize(width: 512, height: 512), "icon.png"),
        ]
        for index in 0..<min(count, Self.maxCount) {
            let (size, name) = shapes[index % shapes.count]
            guard let image = placeholder(size: size, seed: index) else { continue }
            add(image: image, name: name)
        }
    }

    private func placeholder(size: CGSize, seed: Int) -> NSImage? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        rep.size = size

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.current = ctx
        let hue = CGFloat(seed % 6) / 6.0
        NSColor(hue: hue, saturation: 0.5, brightness: 0.55, alpha: 1).setFill()
        NSRect(origin: .zero, size: size).fill()
        NSColor.white.withAlphaComponent(0.75).setStroke()
        let diagonal = NSBezierPath()
        diagonal.move(to: .zero)
        diagonal.line(to: NSPoint(x: size.width, y: size.height))
        diagonal.lineWidth = max(size.width, size.height) / 40
        diagonal.stroke()
        ctx.flushGraphics()

        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }

    // MARK: - Helpers

    private func reject(_ message: String) {
        lastRejection = message
    }

    /// The strip appearing or disappearing changes the dialog's height, and
    /// the window only follows when it is told to.
    private func notifyLayoutChanged() {
        NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
    }

    private func isImageFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return false }
        return type.conforms(to: .image)
    }

    private func mimeType(for url: URL) -> String {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()),
              let mime = type.preferredMIMEType else { return "application/octet-stream" }
        return mime
    }

    /// `NSImage.size` is in points and lies about what is in the bitmap on a
    /// Retina display. The representation's pixel count is the real thing.
    private func pixelSize(of image: NSImage) -> CGSize {
        guard let rep = image.representations.first else { return image.size }
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }

    private func downscaled(_ image: NSImage) -> NSImage? {
        let size = pixelSize(of: image)
        guard size.width > 0, size.height > 0 else { return nil }
        let longest = max(size.width, size.height)
        guard longest > Self.maxLongEdge else { return image }

        let ratio = Self.maxLongEdge / longest
        let target = NSSize(width: floor(size.width * ratio), height: floor(size.height * ratio))
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(target.width), pixelsHigh: Int(target.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        rep.size = target

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.current = ctx
        ctx.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: target))
        ctx.flushGraphics()

        let result = NSImage(size: target)
        result.addRepresentation(rep)
        return result
    }

    private func png(from image: NSImage) -> Data? {
        guard let rep = image.representations.first as? NSBitmapImageRep else {
            guard let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
            return bitmap.representation(using: .png, properties: [:])
        }
        return rep.representation(using: .png, properties: [:])
    }
}
