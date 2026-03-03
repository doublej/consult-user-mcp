import SwiftUI

struct TweakConsoleView: View {
    let editEvent: EditEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let event = editEvent {
                headerBar(event)
                codeBlock(event)
                Spacer(minLength: 0)
            } else {
                emptyState
            }
        }
        .frame(width: 260)
        .background(Theme.Colors.inputBackground)
    }

    private func headerBar(_ event: EditEvent) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.Colors.textMuted)
            Text("\(event.fileName):\(event.lineNumber)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.Colors.cardBackground)
    }

    private func codeBlock(_ event: EditEvent) -> some View {
        let allLines = buildLines(event)
        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(allLines.enumerated()), id: \.offset) { _, entry in
                    codeLine(entry, event: event)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func codeLine(_ entry: CodeLine, event: EditEvent) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Line number gutter
            Text(String(entry.lineNumber))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.Colors.textMuted.opacity(0.6))
                .frame(width: 32, alignment: .trailing)
                .padding(.trailing, 8)

            // Code content
            if entry.isEdited, let range = entry.highlightRange {
                highlightedLine(entry.content, range: range)
            } else {
                Text(truncated(entry.content))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(entry.isEdited ? Theme.Colors.textPrimary : Theme.Colors.textMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(entry.isEdited ? Theme.Colors.accentBlue.opacity(0.05) : Color.clear)
    }

    private func highlightedLine(_ content: String, range: Range<Int>) -> some View {
        let safeStart = min(range.lowerBound, content.count)
        let safeEnd = min(range.upperBound, content.count)

        let startIdx = content.index(content.startIndex, offsetBy: safeStart)
        let endIdx = content.index(content.startIndex, offsetBy: safeEnd)

        let before = String(content[content.startIndex..<startIdx])
        let highlighted = String(content[startIdx..<endIdx])
        let after = String(content[endIdx...])

        return HStack(spacing: 0) {
            Text(before)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.Colors.textPrimary)
            Text(highlighted)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.Colors.accentBlue)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.accentBlue.opacity(0.15))
                        .padding(.horizontal, -1)
                        .padding(.vertical, -1)
                )
            Text(after)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.Colors.textPrimary)
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "slider.horizontal.below.rectangle")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.textMuted.opacity(0.4))
                Text("Move a slider to see changes")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textMuted.opacity(0.6))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func truncated(_ text: String, maxLength: Int = 60) -> String {
        text.count > maxLength ? String(text.prefix(maxLength)) + "..." : text
    }
}

// MARK: - Code Line Model

private struct CodeLine {
    let lineNumber: Int
    let content: String
    let isEdited: Bool
    let highlightRange: Range<Int>?
}

private func buildLines(_ event: EditEvent) -> [CodeLine] {
    var lines: [CodeLine] = []
    let startLine = event.lineNumber - event.contextBefore.count

    for (i, content) in event.contextBefore.enumerated() {
        lines.append(CodeLine(lineNumber: startLine + i, content: content, isEdited: false, highlightRange: nil))
    }

    lines.append(CodeLine(
        lineNumber: event.lineNumber,
        content: event.lineContent,
        isEdited: true,
        highlightRange: event.editRange
    ))

    for (i, content) in event.contextAfter.enumerated() {
        lines.append(CodeLine(lineNumber: event.lineNumber + 1 + i, content: content, isEdited: false, highlightRange: nil))
    }

    return lines
}
