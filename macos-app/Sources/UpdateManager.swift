import Foundation
import AppKit
import os.log

final class UpdateManager {
    static let shared = UpdateManager()

    private let repoOwner = "doublej"
    private let repoName = "consult-user-mcp"
    private let tagPrefix = "macos/v"
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

    func checkForUpdates(includePrerelease: Bool = false, completion: @escaping (Result<Release?, Error>) -> Void) {
        checkForUpdatesWithDetails(includePrerelease: includePrerelease) { result in
            switch result {
            case .success(let checkResult):
                completion(.success(checkResult.release))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func checkForUpdatesWithDetails(
        includePrerelease: Bool = false,
        completion: @escaping (Result<CheckResult, Error>) -> Void
    ) {
        let current = currentVersion
        logger.info("Checking for updates. Current version: \(current)")

        let endpoint = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases?per_page=20"
        guard let url = URL(string: endpoint) else {
            completion(.failure(UpdateError.noRelease))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                self?.logger.error("Update check failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let self = self, let data = data else {
                completion(.failure(UpdateError.noRelease))
                return
            }

            guard let releaseJSON = self.selectRelease(from: data, includePrerelease: includePrerelease),
                  let tagName = releaseJSON["tag_name"] as? String else {
                self.logger.error("Failed to parse release info from GitHub")
                completion(.failure(UpdateError.noRelease))
                return
            }

            let remoteVersion: String
            if tagName.hasPrefix(self.tagPrefix) {
                remoteVersion = String(tagName.dropFirst(self.tagPrefix.count))
            } else if tagName.hasPrefix("v") {
                remoteVersion = String(tagName.dropFirst())
            } else {
                remoteVersion = tagName
            }
            let isNewer = self.isNewer(remote: remoteVersion, current: current)

            self.logger.info("Remote version: \(remoteVersion), Current: \(current), Update available: \(isNewer)")

            if isNewer,
               let assets = releaseJSON["assets"] as? [[String: Any]],
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

    private var downloadDelegate: DownloadDelegate?

    func downloadUpdate(
        from url: URL,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let delegate = DownloadDelegate(progress: progress, completion: completion)
        self.downloadDelegate = delegate

        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: .main)
        let task = session.downloadTask(with: url)
        task.resume()
    }

    func downloadUpdate(from url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        downloadUpdate(from: url, progress: { _ in }, completion: completion)
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
        let remoteParts = versionParts(from: remote)
        let currentParts = versionParts(from: current)

        for i in 0..<max(remoteParts.count, currentParts.count) {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }

    private func versionParts(from version: String) -> [Int] {
        version
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
    }

    private func selectRelease(from data: Data, includePrerelease: Bool) -> [String: Any]? {
        guard let releases = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return releases.first { release in
            let isDraft = release["draft"] as? Bool ?? false
            let isPrerelease = release["prerelease"] as? Bool ?? false
            guard let tag = release["tag_name"] as? String else { return false }
            // Match macos/vX.Y.Z tags, or legacy vX.Y.Z tags (transition period)
            let matchesPlatform = tag.hasPrefix(tagPrefix) || tag.first == "v" && tag.dropFirst().first?.isNumber == true
            return matchesPlatform && !isDraft && (includePrerelease || !isPrerelease)
        }
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let progressHandler: (Double) -> Void
    private let completionHandler: (Result<URL, Error>) -> Void

    init(progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        self.progressHandler = progress
        self.completionHandler = completion
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("update.zip")
        try? FileManager.default.removeItem(at: destURL)

        do {
            try FileManager.default.moveItem(at: location, to: destURL)
            completionHandler(.success(destURL))
        } catch {
            completionHandler(.failure(error))
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler(progress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandler(.failure(error))
        }
    }
}
