// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TetherFlowSimple",
    platforms: [.macOS(.v13)],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TetherFlowSimple",
            path: "Sources"
        )
    ]
)
