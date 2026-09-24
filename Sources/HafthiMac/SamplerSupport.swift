import Foundation

enum SamplerSupport {
    private static var bundledConfigURL: URL? {
        Bundle.module.url(forResource: "SamplerDefault", withExtension: "yml", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: "SamplerDefault", withExtension: "yml")
    }

    static var configURL: URL {
        MacSettings.url.deletingLastPathComponent().appendingPathComponent("sampler.yml")
    }

    static var installedExecutable: String? {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let candidates = ["/opt/homebrew/bin/sampler", "/usr/local/bin/sampler",
                          "/opt/local/bin/sampler", "\(NSHomeDirectory())/go/bin/sampler"]
            + path.split(separator: ":").map { "\($0)/sampler" }
        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }

    @discardableResult
    static func ensureConfig() throws -> URL {
        let url = configURL
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            guard let bundled = bundledConfigURL else {
                throw CocoaError(.fileNoSuchFile)
            }
            try FileManager.default.copyItem(at: bundled, to: url)
        }
        return url
    }

    static func restoreDefault() throws {
        guard let bundled = bundledConfigURL else {
            throw CocoaError(.fileNoSuchFile)
        }
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let data = try Data(contentsOf: bundled)
        try data.write(to: configURL, options: .atomic)
    }
}
