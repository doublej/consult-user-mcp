import Foundation

enum DialogPosition: String, Codable {
    case left
    case center
    case right

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = DialogPosition(rawValue: value) ?? .center
    }
}

struct ConfirmRequest: Codable {
    let body: String
    let title: String
    let confirmLabel: String
    let cancelLabel: String
    let position: DialogPosition?
}

struct ChooseRequest: Codable {
    let body: String
    let title: String?
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let position: DialogPosition?
}

struct TextInputRequest: Codable {
    let body: String
    let title: String
    let defaultValue: String
    let hidden: Bool
    let position: DialogPosition?
}

struct NotifyRequest: Codable {
    let body: String
    let title: String
    let sound: Bool
}

struct PreviewRequest: Codable {
    let body: String
}
