import Foundation

enum OptionalToolSupport {
    static var executableSearchPath: String {
        let standard = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin",
                        "\(NSHomeDirectory())/go/bin", "\(NSHomeDirectory())/.local/bin",
                        "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        let inherited = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":").map(String.init)
        return (standard + inherited).joined(separator: ":")
    }

    static func installedExecutable(named name: String) -> String? {
        executableSearchPath.split(separator: ":").map { "\($0)/\(name)" }
            .first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }
}

enum YaziSupport {
    static var installedExecutable: String? {
        OptionalToolSupport.installedExecutable(named: "yazi")
    }
}
