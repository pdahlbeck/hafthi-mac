import Foundation

enum SamplerSupport {
    private static func bundledConfigURL() throws -> URL {
        if let url = Bundle.main.url(forResource: "SamplerDefault", withExtension: "yml") {
            return url
        }
        // swift run executes from the source tree rather than an .app bundle.
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Resources/SamplerDefault.yml")
        if FileManager.default.fileExists(atPath: source.path) { return source }
        throw NSError(domain: "Hafthi.Sampler", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "The Sampler dashboard config is missing from Hafþi. Reinstall the app and try again."
        ])
    }

    static var configURL: URL {
        MacSettings.url.deletingLastPathComponent().appendingPathComponent("sampler.yml")
    }

    static var executableSearchPath: String {
        let standard = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin",
                        "\(NSHomeDirectory())/go/bin", "\(NSHomeDirectory())/.local/bin",
                        "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        let inherited = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":").map(String.init)
        return (standard + inherited).joined(separator: ":")
    }

    static var installedExecutable: String? {
        executableSearchPath.split(separator: ":").map { "\($0)/sampler" }
            .first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }

    @discardableResult
    static func ensureConfig() throws -> URL {
        let url = configURL
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let bundled = try bundledConfigURL()
            try FileManager.default.copyItem(at: bundled, to: url)
        }
        return url
    }

    static func restoreDefault() throws {
        let bundled = try bundledConfigURL()
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let data = try Data(contentsOf: bundled)
        try data.write(to: configURL, options: .atomic)
    }
}
