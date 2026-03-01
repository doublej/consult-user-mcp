import Foundation

struct TestCase {
    let name: String
    let layout: GridLayout
    let description: String
}

struct TestResult {
    let name: String
    let ascii: String
    let svg: String?
    let summary: String
    let screenshotPath: String?
    let svgPath: String?
}

enum TestRunner {
    static let cases: [TestCase] = [
        TestCase(
            name: "Holy Grail",
            layout: GridLayout(columns: 12, rows: 8, blocks: [
                GridBlock(label: "Header", x: 0, y: 0, w: 12, h: 1),
                GridBlock(label: "Nav", x: 0, y: 1, w: 2, h: 6),
                GridBlock(label: "Content", x: 2, y: 1, w: 8, h: 6),
                GridBlock(label: "Sidebar", x: 10, y: 1, w: 2, h: 6),
                GridBlock(label: "Footer", x: 0, y: 7, w: 12, h: 1),
            ]),
            description: "Classic header/nav/content/sidebar/footer"
        ),
        TestCase(
            name: "Dashboard with Nested Widgets",
            layout: GridLayout(columns: 12, rows: 8, blocks: [
                GridBlock(label: "Header", x: 0, y: 0, w: 12, h: 1),
                GridBlock(label: "Main Panel", x: 0, y: 1, w: 8, h: 7),
                GridBlock(label: "Chart", x: 1, y: 2, w: 3, h: 3),
                GridBlock(label: "Table", x: 4, y: 2, w: 3, h: 3),
                GridBlock(label: "Stats", x: 8, y: 1, w: 4, h: 3),
                GridBlock(label: "Activity", x: 8, y: 4, w: 4, h: 4),
            ]),
            description: "Dashboard with nested chart/table inside main panel"
        ),
        TestCase(
            name: "Mobile Layout",
            layout: GridLayout(columns: 4, rows: 12, blocks: [
                GridBlock(label: "Status Bar", x: 0, y: 0, w: 4, h: 1),
                GridBlock(label: "Hero", x: 0, y: 1, w: 4, h: 3),
                GridBlock(label: "CTA", x: 0, y: 4, w: 4, h: 1),
                GridBlock(label: "Feed", x: 0, y: 5, w: 4, h: 5),
                GridBlock(label: "Tab Bar", x: 0, y: 10, w: 4, h: 1),
            ]),
            description: "Tall narrow mobile screen"
        ),
        TestCase(
            name: "Empty Grid",
            layout: GridLayout(columns: 6, rows: 4, blocks: []),
            description: "Grid with no blocks"
        ),
        TestCase(
            name: "Single Block",
            layout: GridLayout(columns: 6, rows: 4, blocks: [
                GridBlock(label: "Hero", x: 0, y: 0, w: 6, h: 4),
            ]),
            description: "One block filling the entire grid"
        ),
        TestCase(
            name: "Quad Split",
            layout: GridLayout(columns: 8, rows: 6, blocks: [
                GridBlock(label: "Top Left", x: 0, y: 0, w: 4, h: 3),
                GridBlock(label: "Top Right", x: 4, y: 0, w: 4, h: 3),
                GridBlock(label: "Bottom Left", x: 0, y: 3, w: 4, h: 3),
                GridBlock(label: "Bottom Right", x: 4, y: 3, w: 4, h: 3),
            ]),
            description: "Four equal quadrants"
        ),
        TestCase(
            name: "Complex Dashboard",
            layout: GridLayout(columns: 16, rows: 10, blocks: [
                GridBlock(label: "Logo", x: 0, y: 0, w: 3, h: 1),
                GridBlock(label: "Search", x: 3, y: 0, w: 10, h: 1),
                GridBlock(label: "User", x: 13, y: 0, w: 3, h: 1),
                GridBlock(label: "Sidebar", x: 0, y: 1, w: 3, h: 9),
                GridBlock(label: "KPI 1", x: 3, y: 1, w: 4, h: 2),
                GridBlock(label: "KPI 2", x: 7, y: 1, w: 4, h: 2),
                GridBlock(label: "KPI 3", x: 11, y: 1, w: 5, h: 2),
                GridBlock(label: "Chart", x: 3, y: 3, w: 8, h: 4),
                GridBlock(label: "Feed", x: 11, y: 3, w: 5, h: 7),
                GridBlock(label: "Table", x: 3, y: 7, w: 8, h: 3),
            ]),
            description: "Full dashboard with logo, search, KPIs, chart, feed, table"
        ),
        TestCase(
            name: "Brief Detail",
            layout: GridLayout(columns: 12, rows: 8, blocks: [
                GridBlock(label: "Header", x: 0, y: 0, w: 12, h: 1),
                GridBlock(label: "Content", x: 0, y: 1, w: 12, h: 7),
            ]),
            description: "Simple two-block layout for brief detail mode"
        ),
    ]

    @MainActor
    static func run(outputDir: String) -> [TestResult] {
        let screenshotDir = (outputDir as NSString).appendingPathComponent("screenshots")
        let svgDir = (outputDir as NSString).appendingPathComponent("svg")

        try? FileManager.default.createDirectory(atPath: screenshotDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: svgDir, withIntermediateDirectories: true)

        return cases.map { testCase in
            runSingle(testCase, screenshotDir: screenshotDir, svgDir: svgDir)
        }
    }

    @MainActor
    private static func runSingle(_ testCase: TestCase, screenshotDir: String, svgDir: String) -> TestResult {
        var colored = testCase.layout
        colored.blocks = ColorPalette.assignColors(to: colored.blocks)

        let ascii = AsciiRenderer.render(colored)
        let summary = DescriptionRenderer.render(colored)
        let svg = SvgRenderer.render(colored)
        let slug = testCase.name.lowercased().replacingOccurrences(of: " ", with: "-")

        // Save SVG
        var svgPath: String?
        if let svg {
            let path = (svgDir as NSString).appendingPathComponent("\(slug).svg")
            try? svg.write(toFile: path, atomically: true, encoding: .utf8)
            svgPath = path
        }

        // Capture window screenshot
        let screenshotPath = (screenshotDir as NSString).appendingPathComponent("\(slug).png")
        let captured = WindowCapture.capture(layout: colored, title: testCase.name, outputPath: screenshotPath)

        return TestResult(
            name: testCase.name,
            ascii: ascii,
            svg: svg,
            summary: summary,
            screenshotPath: captured ? screenshotPath : nil,
            svgPath: svgPath
        )
    }
}
