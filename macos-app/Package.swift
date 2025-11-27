// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeakSettings",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "SpeakSettings",
            path: "Sources",
            resources: [.process("Resources")]
        )
    ]
)
