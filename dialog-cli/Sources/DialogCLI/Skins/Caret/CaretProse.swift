import AppKit
import SwiftUI

/// The agent's words.
///
/// Inline markers only, consumed never shown, applied links → bold → italic →
/// code (§3.4). Block-level syntax is deliberately not interpreted: a heading,
/// a bullet or a fence arrives as raw characters, and a malformed link stays
/// literal because its pattern simply does not match.
enum CaretProse {

    struct Traits: OptionSet {
        let rawValue: Int
        static let bold = Traits(rawValue: 1 << 0)
        static let italic = Traits(rawValue: 1 << 1)
        static let code = Traits(rawValue: 1 << 2)
    }

    private struct Run {
        var text: String
        var traits: Traits = []
        var link: URL?
    }

    /// Escaped newline and tab sequences become real ones before anything else
    /// looks at the string — which is what makes such a body trip the §3.3
    /// presentation switch.
    static func unescape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\r", with: "")
    }

    /// §3.3: the trigger is the presence of a line break, not the length.
    static func isPassage(_ text: String) -> Bool {
        unescape(text).contains("\n")
    }

    static func attributed(
        _ raw: String,
        font: NSFont,
        emphasis: NSFont,
        colour: Color,
        codeColour: Color,
        linkColour: Color,
        tracking: CGFloat = 0
    ) -> AttributedString {
        var runs = [Run(text: unescape(raw))]
        runs = applyLinks(runs)
        runs = apply(runs, pattern: Self.boldPattern, trait: .bold)
        runs = apply(runs, pattern: Self.italicPattern, trait: .italic)
        runs = apply(runs, pattern: Self.codePattern, trait: .code)

        var out = AttributedString()
        for run in runs where !run.text.isEmpty {
            var piece = AttributedString(run.text)
            let face: NSFont = {
                if run.traits.contains(.code) {
                    return NSFont.monospacedSystemFont(ofSize: font.pointSize * 0.92, weight: .regular)
                }
                var f = run.traits.contains(.bold) ? emphasis : font
                if run.traits.contains(.italic) {
                    f = NSFontManager.shared.convert(f, toHaveTrait: .italicFontMask)
                }
                return f
            }()
            piece.font = Font(face)
            if tracking != 0 { piece.kern = face.pointSize * tracking }
            let ink = run.link != nil ? linkColour : (run.traits.contains(.code) ? codeColour : colour)
            piece.foregroundColor = ink
            if let url = run.link {
                piece.link = url
                piece.underlineStyle = .single
                piece.appKit.underlineStyle = .single
            }
            // The same string set by AppKit, for `CaretSelectableText`.
            piece.appKit.font = face
            piece.appKit.foregroundColor = NSColor(ink)
            if tracking != 0 { piece.appKit.kern = face.pointSize * tracking }
            out.append(piece)
        }
        return out
    }

    // MARK: - Passes

    private static let linkPattern = try! NSRegularExpression(pattern: #"\[([^\]\n]+)\]\(([^)\s]+)\)"#)
    private static let boldPattern = try! NSRegularExpression(pattern: #"\*\*([^*]+)\*\*"#)
    private static let italicPattern = try! NSRegularExpression(pattern: #"(?<!\*)\*([^*\n]+)\*(?!\*)"#)
    private static let codePattern = try! NSRegularExpression(pattern: "`([^`\n]+)`")

    private static func applyLinks(_ runs: [Run]) -> [Run] {
        runs.flatMap { run -> [Run] in
            split(run, pattern: linkPattern) { match, source in
                let label = capture(match, 1, in: source)
                let target = capture(match, 2, in: source)
                guard let url = URL(string: target), url.scheme != nil else { return nil }
                var made = run
                made.text = label
                made.link = url
                return made
            }
        }
    }

    private static func apply(_ runs: [Run], pattern: NSRegularExpression, trait: Traits) -> [Run] {
        runs.flatMap { run -> [Run] in
            // A link's label keeps its own text; markers inside it are left
            // alone so the label always reads as supplied.
            guard run.link == nil else { return [run] }
            return split(run, pattern: pattern) { match, source in
                var made = run
                made.text = capture(match, 1, in: source)
                made.traits.insert(trait)
                return made
            }
        }
    }

    private static func split(
        _ run: Run,
        pattern: NSRegularExpression,
        make: (NSTextCheckingResult, String) -> Run?
    ) -> [Run] {
        let source = run.text
        let full = NSRange(source.startIndex..., in: source)
        let matches = pattern.matches(in: source, range: full)
        guard !matches.isEmpty else { return [run] }

        var out: [Run] = []
        var cursor = full.location
        for match in matches {
            guard let made = make(match, source) else { continue }
            if match.range.location > cursor,
               let plain = Range(NSRange(location: cursor, length: match.range.location - cursor), in: source) {
                var head = run
                head.text = String(source[plain])
                out.append(head)
            }
            out.append(made)
            cursor = match.range.location + match.range.length
        }
        if cursor < full.length,
           let tail = Range(NSRange(location: cursor, length: full.length - cursor), in: source) {
            var rest = run
            rest.text = String(source[tail])
            out.append(rest)
        }
        return out
    }

    private static func capture(_ match: NSTextCheckingResult, _ index: Int, in source: String) -> String {
        guard let range = Range(match.range(at: index), in: source) else { return "" }
        return String(source[range])
    }
}

// MARK: - The two presentations

/// A one-line body is a statement; a body with a line break is a passage
/// (§3.3). They differ in size, in colour and in measure, so the person can
/// tell one from the other before reading a word.
struct CaretBody: View {
    let raw: String
    var forcePassage: Bool = false
    @Environment(\.caretPalette) private var palette

    var body: some View {
        let passage = forcePassage || CaretProse.isPassage(raw)
        CaretSelectableText(text: text(passage: passage),
                            lineSpacing: passage ? CaretStyle.u(4) : CaretStyle.u(2))
            // `idealWidth` as well as `maxWidth`, or the measure is a lie.
            // A cap alone clamps the box and leaves the ideal resolved against
            // the Text's own unbounded single-line width: the view reports one
            // line and draws three, and whatever is sizing the surface at that
            // moment builds a one-line box round them. `CaretChannel` then
            // clips, and the question the person is answering is cut to its
            // first line the instant anything re-measures.
            .frame(idealWidth: passage ? CaretStyle.proseMeasure : CaretStyle.proseMeasure * 0.86,
                   maxWidth: passage ? CaretStyle.proseMeasure : CaretStyle.proseMeasure * 0.86,
                   alignment: .leading)
    }

    private func text(passage: Bool) -> AttributedString {
        CaretProse.attributed(
            raw,
            font: passage ? CaretStyle.body : CaretStyle.statement,
            emphasis: passage ? CaretStyle.bodyEmphasis : NSFont.systemFont(ofSize: CaretStyle.u(17.5), weight: .heavy),
            colour: passage ? palette.context : palette.ink,
            codeColour: palette.caret,
            linkColour: palette.caret,
            tracking: passage ? 0 : CaretStyle.displayTracking
        )
    }
}

/// Selectable prose, set by AppKit.
///
/// SwiftUI's `.textSelection` hands a clicked `Text` to a selection layer that
/// lays the string out again on its own terms: a two-line question was re-set
/// at one line inside the box measured for two, so clicking the question cut
/// it in half. Here one TextKit 1 stack measures and the same typesetter draws
/// and selects, so the box and the lines in it cannot disagree.
struct CaretSelectableText: NSViewRepresentable {
    let text: AttributedString
    let lineSpacing: CGFloat
    @Environment(\.caretPalette) private var palette

    private var string: NSAttributedString {
        let out = NSMutableAttributedString(attributedString: (try? NSAttributedString(text, including: \.appKit)) ?? NSAttributedString())
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        out.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: out.length))
        return out
    }

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView(usingTextLayoutManager: false)
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.widthTracksTextView = true
        return view
    }

    func updateNSView(_ view: NSTextView, context: Context) {
        view.textStorage?.setAttributedString(string)
        view.linkTextAttributes = [
            .foregroundColor: NSColor(palette.caret),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .cursor: NSCursor.pointingHand,
        ]
        view.selectedTextAttributes = [.backgroundColor: NSColor(palette.caret).withAlphaComponent(0.3)]
    }

    /// Measured on a scratch stack, not the view's own: sizing the view's
    /// container for an ideal-width query would leave it drawing at that width.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        let container = NSTextContainer(size: NSSize(width: proposal.width ?? .greatestFiniteMagnitude,
                                                     height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        let layout = NSLayoutManager()
        layout.addTextContainer(container)
        let storage = NSTextStorage(attributedString: string)
        storage.addLayoutManager(layout)
        layout.ensureLayout(for: container)
        let used = layout.usedRect(for: container)
        return CGSize(width: proposal.width ?? ceil(used.width), height: ceil(used.height))
    }
}

/// Prose set at a fixed role — the form's question text, an annotation's
/// quoted subject, the notification's message.
struct CaretProseText: View {
    let raw: String
    let font: NSFont
    let emphasis: NSFont
    let colour: Color
    var measure: CGFloat = CaretStyle.proseMeasure
    var selectable: Bool = true
    @Environment(\.caretPalette) private var palette

    var body: some View {
        prose
            // See `CaretBody`: the cap has to be declared as the ideal too.
            .frame(idealWidth: measure, maxWidth: measure, alignment: .leading)
    }

    @ViewBuilder
    private var prose: some View {
        let text = CaretProse.attributed(
            raw,
            font: font,
            emphasis: emphasis,
            colour: colour,
            codeColour: palette.caret,
            linkColour: palette.caret
        )
        if selectable {
            CaretSelectableText(text: text, lineSpacing: CaretStyle.u(3))
        } else {
            Text(text)
                .lineSpacing(CaretStyle.u(3))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
