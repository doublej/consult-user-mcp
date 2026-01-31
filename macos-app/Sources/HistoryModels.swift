import Foundation

// MARK: - History Entry

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let clientName: String
    let dialogType: String  // "confirm", "choose", "textInput", "questions", "notify"
    let questionSummary: String
    let answer: String?
    let cancelled: Bool
    let snoozed: Bool
}

// MARK: - Legacy History File (for migration)

struct LegacyHistoryFile: Codable {
    var version: Int = 1
    var entries: [HistoryEntry]
}
