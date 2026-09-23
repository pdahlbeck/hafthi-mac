// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HafthiMac",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "HafthiMac", targets: ["HafthiMac"])],
    targets: [
        .target(name: "PTYSupport"),
        .target(name: "TerminalCore"),
        .executableTarget(name: "HafthiMac", dependencies: ["PTYSupport", "TerminalCore"]),
        .testTarget(name: "TerminalCoreTests", dependencies: ["TerminalCore"])
    ]
)
