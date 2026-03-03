import Foundation

enum AppURLs {
    private static let owner = "doublej"
    private static let repo = "consult-user-mcp"

    static let githubIssues = URL(string: "https://github.com/\(owner)/\(repo)/issues")!
    static let releasesAPI = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases?per_page=20")!
    static let releasesJSON = URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/main/docs/src/lib/data/releases.json")!
    static let changelog = URL(string: "https://\(owner).github.io/\(repo)/changelog")!
    static let latestRelease = URL(string: "https://github.com/\(owner)/\(repo)/releases/latest")!
}
