import Foundation

struct ConfirmRequest: Codable {
    let body: String
    let title: String
    let confirmLabel: String
    let cancelLabel: String
    let position: String
}

struct ChooseRequest: Codable {
    let body: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let position: String
}

struct TextInputRequest: Codable {
    let body: String
    let title: String
    let defaultValue: String
    let hidden: Bool
    let position: String
}

struct NotifyRequest: Codable {
    let body: String
    let title: String
    let sound: Bool
}
