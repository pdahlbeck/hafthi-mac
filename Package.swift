// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HafthiMac",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "HafthiMac", targets: ["HafthiMac"])],
    dependencies: [.package(url: "https://github.com/migueldeicaza/SwiftTerm.git", exact: "1.19.0")],
    targets: [.executableTarget(name: "HafthiMac", dependencies: [.product(name: "SwiftTerm", package: "SwiftTerm")],
                                resources: [.copy("Resources/SamplerDefault.yml")])]
)
