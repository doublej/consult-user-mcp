import AppKit
import Foundation

@main
struct SketchCLIApp {
    static func main() {
        SketchCLI.run()
    }
}

@MainActor
enum SketchCLI {
    static func run() {
        let args = CommandLine.arguments

        guard args.count >= 2 else {
            fputs("Usage: SketchCLI <command> [json]\n", stderr)
            fputs("Commands: templates, describe, propose, test\n", stderr)
            exit(1)
        }

        let command = args[1]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        switch command {
        case "templates":
            let response = TemplatesResponse(templates: DensityTemplate.builtIn)
            outputJSON(response, encoder: encoder)

        case "describe":
            guard args.count >= 3 else {
                fputs("Usage: SketchCLI describe <json>\n", stderr)
                exit(1)
            }
            handleDescribe(args[2], encoder: encoder)

        case "render":
            guard args.count >= 3 else {
                fputs("Usage: SketchCLI render <json>\n", stderr)
                exit(1)
            }
            handleRender(args[2], encoder: encoder)

        case "propose":
            guard args.count >= 3 else {
                fputs("Usage: SketchCLI propose <json>\n", stderr)
                exit(1)
            }
            handlePropose(args[2], encoder: encoder)

        case "test":
            handleTest(args, encoder: encoder)

        default:
            fputs("Unknown command: \(command)\n", stderr)
            exit(1)
        }
    }

    private static func resolveDescribeLayout(_ jsonInput: String) -> (GridLayout, String) {
        guard let data = jsonInput.data(using: .utf8),
              let request = try? JSONDecoder().decode(DescribeRequest.self, from: data) else {
            fputs("Invalid describe request JSON\n", stderr)
            exit(1)
        }

        let layout = GridLayout(
            columns: request.columns,
            rows: request.rows,
            blocks: request.resolvedBlocks()
        )
        return (layout, request.detail ?? "full")
    }

    private static func handleDescribe(_ jsonInput: String, encoder: JSONEncoder) {
        let (layout, detail) = resolveDescribeLayout(jsonInput)

        let summary = DescriptionRenderer.render(layout, detail: detail)
        let ascii = AsciiRenderer.render(layout)

        let response = DescribeResponse(summary: summary, ascii: ascii)
        outputJSON(response, encoder: encoder)
    }

    private static func handleRender(_ jsonInput: String, encoder: JSONEncoder) {
        let (layout, detail) = resolveDescribeLayout(jsonInput)

        let summary = DescriptionRenderer.render(layout, detail: detail)
        let ascii = AsciiRenderer.render(layout)
        let image = SvgRenderer.render(layout)

        let response = LayoutResponse(
            status: "rendered",
            layout: layout,
            ascii: ascii,
            image: image,
            summary: summary,
            changes: nil
        )
        outputJSON(response, encoder: encoder)
    }

    private static func handlePropose(_ jsonInput: String, encoder: JSONEncoder) {
        guard let data = jsonInput.data(using: .utf8),
              let request = try? JSONDecoder().decode(ProposeLayoutRequest.self, from: data) else {
            fputs("Invalid propose request JSON\n", stderr)
            exit(1)
        }

        // Set theme from request
        if let themeStr = request.theme?.lowercased() {
            Theme.current = themeStr == "light" ? .light : .dark
        }

        let layout = request.resolvedLayout()

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        setupEditMenu()

        let manager = SketchManager.shared
        let response = manager.propose(layout: layout, title: request.title, description: request.description)
        outputJSON(response, encoder: encoder)
    }

    private static func handleTest(_ args: [String], encoder: JSONEncoder) {
        let outputDir: String
        if let idx = args.firstIndex(of: "--output"), idx + 1 < args.count {
            outputDir = args[idx + 1]
        } else {
            outputDir = (FileManager.default.currentDirectoryPath as NSString)
                .appendingPathComponent("test-report")
        }

        try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        fputs("Running \(TestRunner.cases.count) test cases...\n", stderr)
        let results = TestRunner.run(outputDir: outputDir)

        let reportPath = HtmlReportGenerator.generate(results: results, outputDir: outputDir)

        let captured = results.filter { $0.screenshotPath != nil }.count
        fputs("Done: \(results.count) cases, \(captured) screenshots captured\n", stderr)

        let response: [String: String] = ["report": reportPath, "outputDir": outputDir]
        outputJSON(response, encoder: encoder)
    }

    private static func setupEditMenu() {
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

    private static func outputJSON<T: Encodable>(_ value: T, encoder: JSONEncoder) {
        guard let data = try? encoder.encode(value),
              let output = String(data: data, encoding: .utf8) else {
            fputs("Failed to encode response\n", stderr)
            exit(1)
        }
        print(output)
    }
}
