import Foundation
import Combine

// MARK: - Project Model

struct Project: Codable, Identifiable, Equatable {
    var id: String { path }
    let path: String
    var displayName: String
    var lastSeen: Date

    var folderName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    init(path: String, displayName: String? = nil, lastSeen: Date = Date()) {
        self.path = path
        self.displayName = displayName ?? URL(fileURLWithPath: path).lastPathComponent
        self.lastSeen = lastSeen
    }
}

// MARK: - Projects File

private struct ProjectsFile: Codable {
    var projects: [Project]
}

// MARK: - Project Manager

final class ProjectManager: ObservableObject {
    static let shared = ProjectManager()

    @Published private(set) var projects: [Project] = []

    private let configURL: URL
    private var fileMonitor: DispatchSourceFileSystemObject?

    private init() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("consult-user-mcp")

        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        configURL = configDir.appendingPathComponent("projects.json")

        loadFromFile()
        startFileMonitoring()
    }

    // MARK: - CRUD Operations

    func addOrUpdate(path: String) {
        let normalizedPath = (path as NSString).standardizingPath

        if let index = projects.firstIndex(where: { $0.path == normalizedPath }) {
            projects[index].lastSeen = Date()
        } else {
            let project = Project(path: normalizedPath)
            projects.append(project)
        }

        sortProjects()
        saveToFile()
    }

    func rename(path: String, to newName: String) {
        guard let index = projects.firstIndex(where: { $0.path == path }) else { return }
        projects[index].displayName = newName.isEmpty ? projects[index].folderName : newName
        saveToFile()
    }

    func remove(path: String) {
        projects.removeAll { $0.path == path }
        saveToFile()
    }

    func removeAll() {
        projects.removeAll()
        saveToFile()
    }

    func project(for path: String) -> Project? {
        let normalizedPath = (path as NSString).standardizingPath
        return projects.first { $0.path == normalizedPath }
    }

    // MARK: - Persistence

    private func loadFromFile() {
        guard let data = try? Data(contentsOf: configURL) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let file = try? decoder.decode(ProjectsFile.self, from: data) else { return }
        projects = file.projects
        sortProjects()
    }

    private func saveToFile() {
        let file = ProjectsFile(projects: projects)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(file) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    private func sortProjects() {
        projects.sort { $0.lastSeen > $1.lastSeen }
    }

    // MARK: - File Monitoring

    private func startFileMonitoring() {
        let fd = open(configURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )

        fileMonitor?.setEventHandler { [weak self] in
            self?.loadFromFile()
        }

        fileMonitor?.setCancelHandler {
            close(fd)
        }

        fileMonitor?.resume()
    }
}
