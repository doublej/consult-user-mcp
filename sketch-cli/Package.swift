// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SketchCLI",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SketchCLI",
            path: "Sources/SketchCLI"
        )
    ]
)
