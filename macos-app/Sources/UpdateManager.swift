import Foundation
import AppKit
import os.log

final class UpdateManager {
    static let shared = UpdateManager()

    private let repoOwner = "doublej"
    private let repoName = "consult-user-mcp"
    private let logger = Logger(subsystem: "com.consultuser.mcp", category: "UpdateManager")

    struct Release {
        let version: String
        let zipURL: URL
    }

    struct CheckResult {
        let currentVersion: String
        let remoteVersion: String?
        let release: Release?
        let isUpdateAvailable: Bool
    }

    enum UpdateError: LocalizedError {
        case noRelease, noAsset, downloadFailed, scriptNotFound

        var errorDescription: String? {
            switch self {
            case .noRelease: return "Could not fetch release info"
            case .noAsset: return "No download asset found"
            case .downloadFailed: return "Download failed"
            case .scriptNotFound: return "Update script not found"
            }
        }
    }

    private init() {}

    // MARK: - Version

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    // MARK: - Check for Updates

    func checkForUpdates(completion: @escaping (Result<Release?, Error>) -> Void) {
        checkForUpdatesWithDetails { result in
            switch result {
            case .success(let checkResult):
                completion(.success(checkResult.release))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func checkForUpdatesWithDetails(completion: @escaping (Result<CheckResult, Error>) -> Void) {
        let current = currentVersion
        logger.info("Checking for updates. Current version: \(current)")

        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                self?.logger.error("Update check failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                self?.logger.error("Failed to parse release info from GitHub")
                completion(.failure(UpdateError.noRelease))
                return
            }

            let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            let isNewer = self.isNewer(remote: remoteVersion, current: current)

            self.logger.info("Remote version: \(remoteVersion), Current: \(current), Update available: \(isNewer)")

            if isNewer,
               let assets = json["assets"] as? [[String: Any]],
               let zipAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".zip") == true }),
               let downloadURL = zipAsset["browser_download_url"] as? String,
               let url = URL(string: downloadURL) {
                let release = Release(version: remoteVersion, zipURL: url)
                let result = CheckResult(
                    currentVersion: current,
                    remoteVersion: remoteVersion,
                    release: release,
                    isUpdateAvailable: true
                )
                completion(.success(result))
            } else {
                let result = CheckResult(
                    currentVersion: current,
                    remoteVersion: remoteVersion,
                    release: nil,
                    isUpdateAvailable: false
                )
                completion(.success(result))
            }
        }.resume()
    }

    // MARK: - Download

    func downloadUpdate(from url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                completion(.failure(UpdateError.downloadFailed))
                return
            }

            let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("update.zip")
            try? FileManager.default.removeItem(at: destURL)

            do {
                try FileManager.default.moveItem(at: tempURL, to: destURL)
                completion(.success(destURL))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    // MARK: - Install

    func installUpdate(zipPath: URL) throws {
        guard let scriptPath = Bundle.main.path(forResource: "update", ofType: "sh") else {
            throw UpdateError.scriptNotFound
        }

        let pid = ProcessInfo.processInfo.processIdentifier

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath, zipPath.path, String(pid)]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - Semver Compare

    private func isNewer(remote: String, current: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(remoteParts.count, currentParts.count) {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }
}
