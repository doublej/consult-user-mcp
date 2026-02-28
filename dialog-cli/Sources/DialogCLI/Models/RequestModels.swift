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
    let allowOther: Bool
    let defaultSelection: String?
    let position: DialogPosition?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        body = try container.decode(String.self, forKey: .body)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        choices = try container.decode([String].self, forKey: .choices)
        descriptions = try container.decodeIfPresent([String].self, forKey: .descriptions)
        allowMultiple = try container.decodeIfPresent(Bool.self, forKey: .allowMultiple) ?? false
        allowOther = try container.decodeIfPresent(Bool.self, forKey: .allowOther) ?? true
        defaultSelection = try container.decodeIfPresent(String.self, forKey: .defaultSelection)
        position = try container.decodeIfPresent(DialogPosition.self, forKey: .position)
    }
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
