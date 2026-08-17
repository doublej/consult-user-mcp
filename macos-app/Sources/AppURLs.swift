import Foundation

enum AppURLs {
    private static let owner = "doublej"
    private static let repo = "consult-user-mcp"

    static let githubIssues = URL(string: "https://github.com/\(owner)/\(repo)/issues")!
    static let releasesAPI = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases?per_page=20")!
    /// Change-list sources, in the order they are tried. The Pages copy is
    /// published by the docs build from the same `releases.json`; the raw
    /// GitHub URL stays as a fallback for when Pages has not deployed yet.
    static let releasesJSONSources = [
        URL(string: "https://\(owner).github.io/\(repo)/releases.json")!,
        URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/main/docs/src/lib/data/releases.json")!,
    ]
    static let changelog = URL(string: "https://\(owner).github.io/\(repo)/changelog")!
    static let latestRelease = URL(string: "https://github.com/\(owner)/\(repo)/releases/latest")!
}
