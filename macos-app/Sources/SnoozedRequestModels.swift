import Foundation

struct SnoozedRequest: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let clientName: String
    let dialogType: String
    let summary: String
}
