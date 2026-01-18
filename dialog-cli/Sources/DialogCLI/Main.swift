import AppKit
import Foundation

// MARK: - Pulse Response

struct PulseResponse: Codable {
    let success: Bool
}

@main
struct DialogCLIApp {
    static func main() {
        DialogCLI.run()
    }
}

enum DialogCLI {
    static func setupEditMenu() {
    let mainMenu = NSMenu()
    let editMenuItem = NSMenuItem()
    let editMenu = NSMenu(title: "Edit")
    editMenuItem.submenu = editMenu

    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

    mainMenu.addItem(editMenuItem)
    NSApp.mainMenu = mainMenu
}

static func run() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    setupEditMenu()

    let args = CommandLine.arguments
    guard args.count >= 2 else {
        fputs("Usage: dialog-cli <command> [json]\n", stderr)
        fputs("Commands: confirm, choose, textInput, notify, questions, pulse\n", stderr)
        exit(1)
    }

    let command = args[1]

    // Handle pulse command separately (no JSON needed)
    if command == "pulse" {
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.consult-user-mcp.pulse"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        let response = PulseResponse(success: true)
        if let data = try? JSONEncoder().encode(response),
           let output = String(data: data, encoding: .utf8) {
            print(output)
        }
        exit(0)
    }

    guard args.count >= 3 else {
        fputs("Usage: dialog-cli <command> <json>\n", stderr)
        fputs("Commands: confirm, choose, textInput, notify, questions, pulse\n", stderr)
        exit(1)
    }

    let jsonInput = args[2]

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    let manager = DialogManager.shared

    if let clientName = ProcessInfo.processInfo.environment["MCP_CLIENT_NAME"] {
        manager.setClientName(clientName)
    }

    // Set theme from environment variable
    if let themeName = ProcessInfo.processInfo.environment["DIALOG_THEME"] {
        ThemeManager.shared.setTheme(named: themeName)
    }

    guard let jsonData = jsonInput.data(using: .utf8) else {
        fputs("Invalid JSON input\n", stderr)
        exit(1)
    }

    var outputData: Data?

    switch command {
    case "confirm":
        guard let request = try? decoder.decode(ConfirmRequest.self, from: jsonData) else {
            fputs("Invalid confirm request\n", stderr)
            exit(1)
        }
        let response = manager.confirm(request)
        outputData = try? encoder.encode(response)

    case "choose":
        guard let request = try? decoder.decode(ChooseRequest.self, from: jsonData) else {
            fputs("Invalid choose request\n", stderr)
            exit(1)
        }
        let response = manager.choose(request)
        outputData = try? encoder.encode(response)

    case "textInput":
        guard let request = try? decoder.decode(TextInputRequest.self, from: jsonData) else {
            fputs("Invalid textInput request\n", stderr)
            exit(1)
        }
        let response = manager.textInput(request)
        outputData = try? encoder.encode(response)

    case "notify":
        guard let request = try? decoder.decode(NotifyRequest.self, from: jsonData) else {
            fputs("Invalid notify request\n", stderr)
            exit(1)
        }
        let response = manager.notify(request)
        outputData = try? encoder.encode(response)

    case "questions":
        guard let request = try? decoder.decode(QuestionsRequest.self, from: jsonData) else {
            fputs("Invalid questions request\n", stderr)
            exit(1)
        }
        let response = manager.questions(request)
        outputData = try? encoder.encode(response)

    default:
        fputs("Unknown command: \(command)\n", stderr)
        exit(1)
    }

    if let data = outputData, let output = String(data: data, encoding: .utf8) {
        print(output)
    } else {
        fputs("Failed to encode response\n", stderr)
        exit(1)
    }
}
}
