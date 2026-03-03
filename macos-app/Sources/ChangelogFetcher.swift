import Foundation

final class ChangelogFetcher {
    static let shared = ChangelogFetcher()

    private let url = AppURLs.releasesJSON
    private var cache: (targetVersion: String, releases: [ChangelogRelease])?

    private init() {}

    func fetch(
        currentVersion: String,
        targetVersion: String,
        completion: @escaping ([ChangelogRelease]) -> Void
    ) {
        if let cache, cache.targetVersion == targetVersion {
            completion(cache.releases)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil,
                  let file = try? JSONDecoder().decode(ChangelogFile.self, from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let filtered = file.releases
                .filter { $0.platform == "macos" }
                .filter { Self.isNewer($0.version, than: currentVersion) }
                .filter { !Self.isNewer($0.version, than: targetVersion) }
                .sorted { Self.isNewer($0.version, than: $1.version) }

            self.cache = (targetVersion, filtered)
            DispatchQueue.main.async { completion(filtered) }
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
