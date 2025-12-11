// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConsultUserMCP",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ConsultUserMCP",
            path: "Sources",
            resources: [.process("Resources")]
        )
    ]
)
