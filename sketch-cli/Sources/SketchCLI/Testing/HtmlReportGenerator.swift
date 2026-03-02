import Foundation

enum HtmlReportGenerator {
    static func generate(results: [TestResult], outputDir: String) -> String {
        let reportPath = (outputDir as NSString).appendingPathComponent("report.html")
        let html = buildHtml(results: results)
        try? html.write(toFile: reportPath, atomically: true, encoding: .utf8)
        return reportPath
    }

    private static func buildHtml(results: [TestResult]) -> String {
        var cards = ""
        for result in results {
            cards += cardHtml(result)
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SketchCLI Test Report</title>
        <style>
        \(css)
        </style>
        </head>
        <body>
        <header>
            <h1>SketchCLI Test Report</h1>
            <p>\(results.count) test cases &middot; Generated \(timestamp())</p>
        </header>
        <main>
        \(cards)
        </main>
        </body>
        </html>
        """
    }

    private static func cardHtml(_ result: TestResult) -> String {
        let svgColumn = svgColumnHtml(result)
        let screenshotColumn = screenshotColumnHtml(result)

        return """
        <section class="card">
            <h2>\(escapeHtml(result.name))</h2>
            <div class="comparison">
                \(svgColumn)
                \(screenshotColumn)
            </div>
            <div class="details">
                <div class="ascii-block">
                    <h3>ASCII</h3>
                    <pre>\(escapeHtml(result.ascii))</pre>
                </div>
                <div class="summary-block">
                    <h3>Summary</h3>
                    <pre>\(escapeHtml(result.summary))</pre>
                </div>
            </div>
        </section>
        """
    }

    private static func svgColumnHtml(_ result: TestResult) -> String {
        guard let svg = result.svg else {
            return """
            <div class="render-col">
                <h3>SVG Render</h3>
                <p class="empty">No SVG generated</p>
            </div>
            """
        }
        return """
        <div class="render-col">
            <h3>SVG Render</h3>
            <div class="svg-container">\(svg)</div>
        </div>
        """
    }

    private static func screenshotColumnHtml(_ result: TestResult) -> String {
        guard let path = result.screenshotPath,
              let data = FileManager.default.contents(atPath: path) else {
            return """
            <div class="render-col">
                <h3>Window Screenshot</h3>
                <p class="empty">No screenshot captured</p>
            </div>
            """
        }
        let base64 = data.base64EncodedString()
        return """
        <div class="render-col">
            <h3>Window Screenshot</h3>
            <img src="data:image/png;base64,\(base64)" alt="\(escapeHtml(result.name)) screenshot">
        </div>
        """
    }

    private static func escapeHtml(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: Date())
    }

    private static let css = """
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        background: #111114;
        color: #e0e0e0;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        padding: 2rem;
    }
    header {
        text-align: center;
        margin-bottom: 2rem;
    }
    header h1 { font-size: 1.8rem; color: #fff; }
    header p { color: #888; margin-top: 0.5rem; }
    main { max-width: 1200px; margin: 0 auto; }
    .card {
        background: #1a1a1e;
        border-radius: 12px;
        padding: 1.5rem;
        margin-bottom: 2rem;
        border: 1px solid #2a2a2e;
    }
    .card h2 {
        font-size: 1.3rem;
        color: #fff;
        margin-bottom: 1rem;
        padding-bottom: 0.5rem;
        border-bottom: 1px solid #2a2a2e;
    }
    .card h3 {
        font-size: 0.85rem;
        color: #888;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        margin-bottom: 0.5rem;
    }
    .comparison {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1.5rem;
        margin-bottom: 1rem;
    }
    .render-col img, .svg-container svg {
        width: 100%;
        height: auto;
        border-radius: 8px;
        border: 1px solid #333;
    }
    .details {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1.5rem;
    }
    pre {
        background: #0d0d10;
        padding: 1rem;
        border-radius: 8px;
        overflow-x: auto;
        font-size: 0.8rem;
        line-height: 1.4;
        color: #ccc;
        border: 1px solid #222;
    }
    .empty { color: #666; font-style: italic; }
    """
}
