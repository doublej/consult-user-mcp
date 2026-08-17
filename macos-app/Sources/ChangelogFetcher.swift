import Foundation

/// Fetches the change list shown before an update.
///
/// Two sources, tried in order. The docs site is first because it is a plain
/// static asset on our own Pages deployment; `raw.githubusercontent.com` is the
/// fallback and is heavily rate-limited for unauthenticated callers — a 429 or
/// a 503 from it is routine, not exceptional.
final class ChangelogFetcher {
    static let shared = ChangelogFetcher()

    /// `nil` means the fetch failed. An empty array means it succeeded and
    /// there is genuinely nothing between the two versions. Conflating those
    /// was the whole bug: every network failure read as "no changes", and the
    /// view could only report "could not load" by guessing from emptiness.
    typealias Completion = ([ChangelogRelease]?) -> Void

    private var cache: (targetVersion: String, releases: [ChangelogRelease])?

    private init() {}

    func fetch(currentVersion: String, targetVersion: String, completion: @escaping Completion) {
        if let cache, cache.targetVersion == targetVersion {
            completion(cache.releases)
            return
        }

        load(AppURLs.releasesJSONSources, attemptsLeft: 2) { [weak self] file in
            guard let self, let file else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let filtered = file.releases
                .filter { $0.platform == "macos" }
                .filter { Self.isNewer($0.version, than: currentVersion) }
                .filter { !Self.isNewer($0.version, than: targetVersion) }
                .sorted { Self.isNewer($0.version, than: $1.version) }

            self.cache = (targetVersion, filtered)
            DispatchQueue.main.async { completion(filtered) }
        }
    }

    // MARK: - Loading

    /// Walks the source list, then retries the whole list after a short pause.
    /// GitHub's rate limiting and its occasional 503s both clear on their own.
    private func load(
        _ sources: [URL],
        attemptsLeft: Int,
        completion: @escaping (ChangelogFile?) -> Void
    ) {
        guard let url = sources.first else {
            guard attemptsLeft > 1 else {
                completion(nil)
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.load(AppURLs.releasesJSONSources, attemptsLeft: attemptsLeft - 1, completion: completion)
            }
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        // Without this a CDN can hand back a stale copy that predates the
        // release being offered, so the change list comes back empty for the
        // one version the user is being asked about.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            let rest = Array(sources.dropFirst())
            // The status code was never checked. A 429 or a 503 arrives as a
            // perfectly good `data` with a nil error — the body is just an HTML
            // error page — so the only symptom was a decode failure that looked
            // exactly like an empty changelog.
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status), let data,
                  let file = try? JSONDecoder().decode(ChangelogFile.self, from: data) else {
                self?.load(rest, attemptsLeft: attemptsLeft, completion: completion)
                return
            }
            completion(file)
        }.resume()
    }

    // MARK: - Semver

    private static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = parts(a), pb = parts(b)
        for i in 0..<max(pa.count, pb.count) {
            let va = i < pa.count ? pa[i] : 0
            let vb = i < pb.count ? pb[i] : 0
            if va != vb { return va > vb }
        }
        return false
    }

    private static func parts(_ version: String) -> [Int] {
        version.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
    }
}
