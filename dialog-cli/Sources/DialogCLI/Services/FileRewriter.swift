import Foundation

private let rewriterLogPath = "/tmp/consult-user-rewriter.log"

private func debugLog(_ message: String) {
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
    if let handle = FileHandle(forWritingAtPath: rewriterLogPath) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: rewriterLogPath, contents: line.data(using: .utf8))
    }
}

enum RewriteError: Error {
    case verificationFailed(paramId: String, expected: String, found: String)
    case fileReadError(path: String)
    case writeError(path: String)
    case outsideProjectRoot(path: String)
}

final class FileRewriter {
    struct TrackedParam {
        let id: String
        let filePath: String
        var line: Int      // 1-indexed
        var column: Int    // 1-indexed
        var expectedText: String
        let originalText: String
        let originalValue: Double
        let min: Double
        let max: Double
        let step: Double?
        let unit: String?
    }

    private var params: [String: TrackedParam]
    private let projectPath: String?

    init(parameters: [TweakParameter], projectPath: String?) {
        self.projectPath = projectPath
        var map: [String: TrackedParam] = [:]
        for p in parameters {
            let resolvedPath = p.file.hasPrefix("/") ? p.file
                : projectPath.map { ($0 as NSString).appendingPathComponent(p.file) } ?? p.file
            map[p.id] = TrackedParam(
                id: p.id,
                filePath: resolvedPath,
                line: p.line,
                column: p.column,
                expectedText: p.expectedText,
                originalText: p.expectedText,
                originalValue: p.current,
                min: p.min,
                max: p.max,
                step: p.step,
                unit: p.unit
            )
        }
        self.params = map
        for p in parameters {
            debugLog("init param '\(p.id)': file=\(p.file) L\(p.line):C\(p.column) expectedText='\(p.expectedText)'")
        }
    }

    func applyChange(paramId: String, newValue: Double) -> Result<Void, RewriteError> {
        guard var param = params[paramId] else { return .success(()) }

        // Security: reject writes outside project root
        if let root = projectPath {
            let resolved = (param.filePath as NSString).standardizingPath
            let rootResolved = (root as NSString).standardizingPath
            guard resolved.hasPrefix(rootResolved + "/") || resolved == rootResolved else {
                return .failure(.outsideProjectRoot(path: param.filePath))
            }
        }

        // Read file
        guard let content = try? String(contentsOfFile: param.filePath, encoding: .utf8) else {
            debugLog("file read error for '\(paramId)': cannot read '\(param.filePath)'")
            return .failure(.fileReadError(path: param.filePath))
        }

        var lines = content.components(separatedBy: "\n")
        let lineIndex = param.line - 1
        guard lineIndex >= 0, lineIndex < lines.count else {
            return .failure(.fileReadError(path: param.filePath))
        }

        let line = lines[lineIndex]
        let colIndex = param.column - 1

        // Find expectedText: try exact column first, then search nearby
        guard let matchCol = findExpectedText(param.expectedText, in: line, near: colIndex) else {
            let context = safeSubstring(line, from: colIndex, length: param.expectedText.count)
            debugLog("verification failed for '\(paramId)': expected '\(param.expectedText)' at L\(param.line):C\(param.column), found '\(context)'")
            debugLog("full line (\(line.count) chars): '\(line)'")
            return .failure(.verificationFailed(paramId: paramId, expected: param.expectedText, found: context))
        }

        // Update column if it shifted
        if matchCol != colIndex {
            debugLog("column adjusted for '\(paramId)': C\(param.column) → C\(matchCol + 1)")
            param.column = matchCol + 1
            params[paramId] = param
        }

        // Format new value
        let expectedLen = param.expectedText.count
        let newText = formatValue(newValue, matching: param.expectedText, step: param.step)
        let lengthDiff = newText.count - expectedLen

        // Replace text in line
        let startIdx = line.index(line.startIndex, offsetBy: matchCol)
        let endIdx = line.index(startIdx, offsetBy: expectedLen)
        let prefix = String(line[line.startIndex..<startIdx])
        let suffix = String(line[endIdx...])
        lines[lineIndex] = prefix + newText + suffix

        // Adjust columns for sibling params on same file + line
        for (otherId, var other) in params where otherId != paramId {
            guard other.filePath == param.filePath, other.line == param.line else { continue }
            if other.column > param.column {
                other.column += lengthDiff
                params[otherId] = other
            }
        }

        // Atomic write (atomically: true uses temp+rename internally)
        let newContent = lines.joined(separator: "\n")
        do {
            try newContent.write(toFile: param.filePath, atomically: true, encoding: .utf8)
        } catch {
            debugLog("write error for '\(paramId)': \(error)")
            return .failure(.writeError(path: param.filePath))
        }

        // Update tracked state
        param.expectedText = newText
        params[paramId] = param

        return .success(())
    }

    func formatValue(_ value: Double, matching expectedText: String, step: Double?) -> String {
        // Separate numeric part from unit suffix (e.g. "2.5rem" → "2.5" + "rem")
        let (numericText, suffix) = splitNumericSuffix(expectedText)

        // Integer check: no decimal point in numeric part
        if !numericText.contains(".") {
            return String(Int(value.rounded())) + suffix
        }

        // Count decimal places in numeric part
        let parts = numericText.split(separator: ".", maxSplits: 1)
        let expectedDecimals = parts.count > 1 ? parts[1].count : 0

        // Use step precision if higher
        let stepDecimals = step.map { decimalPlaces(in: $0) } ?? 0
        let decimals = max(expectedDecimals, stepDecimals)

        let formatted = String(format: "%.\(decimals)f", value)

        // Preserve no-leading-zero style (e.g. ".5" instead of "0.5")
        if numericText.hasPrefix(".") && formatted.hasPrefix("0.") {
            return String(formatted.dropFirst()) + suffix
        }

        return formatted + suffix
    }

    /// Splits "2.5rem" → ("2.5", "rem"), "-0.03em" → ("-0.03", "em"), "300" → ("300", "")
    private func splitNumericSuffix(_ text: String) -> (String, String) {
        // Find where the trailing non-numeric suffix starts
        var numericEnd = text.endIndex
        for i in text.indices.reversed() {
            let c = text[i]
            if c.isNumber || c == "." || c == "-" || c == "+" {
                numericEnd = text.index(after: i)
                break
            }
        }
        if numericEnd == text.startIndex && !text.isEmpty {
            // Entire string is non-numeric — treat as-is
            return (text, "")
        }
        return (String(text[text.startIndex..<numericEnd]), String(text[numericEnd...]))
    }

    func resetParam(id: String) -> Result<Double, RewriteError> {
        guard let param = params[id] else { return .success(0) }
        let result = applyChange(paramId: id, newValue: param.originalValue)
        switch result {
        case .success:
            return .success(param.originalValue)
        case .failure(let error):
            return .failure(error)
        }
    }

    func resetAll() -> [String: Result<Double, RewriteError>] {
        var results: [String: Result<Double, RewriteError>] = [:]
        for (id, _) in params {
            results[id] = resetParam(id: id)
        }
        return results
    }

    func currentValues() -> [String: Double] {
        var values: [String: Double] = [:]
        for (id, param) in params {
            if let val = Double(param.expectedText) {
                values[id] = val
            } else if param.expectedText.hasPrefix("."), let val = Double("0" + param.expectedText) {
                values[id] = val
            } else {
                values[id] = param.originalValue
            }
        }
        return values
    }

    private func decimalPlaces(in value: Double) -> Int {
        let str = String(value)
        guard let dotIndex = str.firstIndex(of: ".") else { return 0 }
        let afterDot = str[str.index(after: dotIndex)...]
        let trimmed = afterDot.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        return trimmed.count
    }

    /// Search for expectedText in line, starting at hintCol and expanding outward (max 5 chars)
    private func findExpectedText(_ expected: String, in line: String, near hintCol: Int) -> Int? {
        let len = expected.count
        guard len > 0, len <= line.count else { return nil }

        // Try exact position first
        if matchAt(expected, in: line, col: hintCol) { return hintCol }

        // Search nearby (up to 5 positions in each direction)
        for offset in 1...5 {
            if matchAt(expected, in: line, col: hintCol + offset) { return hintCol + offset }
            if matchAt(expected, in: line, col: hintCol - offset) { return hintCol - offset }
        }
        return nil
    }

    private func matchAt(_ expected: String, in line: String, col: Int) -> Bool {
        guard col >= 0, col + expected.count <= line.count else { return false }
        let start = line.index(line.startIndex, offsetBy: col)
        let end = line.index(start, offsetBy: expected.count)
        return String(line[start..<end]) == expected
    }

    private func safeSubstring(_ line: String, from col: Int, length: Int) -> String {
        guard col >= 0, col < line.count else { return "out of bounds" }
        let start = line.index(line.startIndex, offsetBy: col)
        let end = line.index(start, offsetBy: min(length, line.count - col))
        return String(line[start..<end])
    }
}
