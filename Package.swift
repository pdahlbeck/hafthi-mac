// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HafthiMac",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "HafthiMac", targets: ["HafthiMac"])],
    targets: [.executableTarget(name: "HafthiMac")]
)
