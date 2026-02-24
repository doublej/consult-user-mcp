import Foundation

struct TweakParameter: Codable {
    let id: String
    let label: String
    let element: String?
    let file: String
    let line: Int
    let column: Int
    let expectedText: String
    let current: Double
    let min: Double
    let max: Double
    let step: Double?
    let unit: String?
}

extension TweakParameter {
    var effectiveStep: Double {
        if let step { return step }
        let range = max - min
        if range <= 0 { return 1 }
        let rawStep = range / 100.0
        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude
        let niceStep: Double
        if normalized <= 1 { niceStep = 1 }
        else if normalized <= 2 { niceStep = 2 }
        else if normalized <= 5 { niceStep = 5 }
        else { niceStep = 10 }
        return niceStep * magnitude
    }
}

struct TweakRequest: Codable {
    let body: String
    let parameters: [TweakParameter]
    let position: DialogPosition
}

struct TweakResponse: Codable {
    let dialogType: String
    let answers: [String: Double]
    let action: String?  // "file" or "agent", nil when cancelled/snoozed
    let cancelled: Bool
    let dismissed: Bool
    let snoozed: Bool?
    let snoozeMinutes: Int?
    let remainingSeconds: Int?
    let feedbackText: String?
    let askDifferently: String?
    let instruction: String?
    let replayAnimations: Bool?  // Request browser to replay CSS animations
}
