import Darwin
import Foundation

enum CommandHelp {
    static func handleIfRequested() {
        guard CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--ask" else { return }
        let question = CommandLine.arguments.dropFirst(2).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            fputs("Enter a question for tgpt.\n", stderr)
            exit(1)
        }
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let candidates = ["/opt/homebrew/bin/tgpt", "/usr/local/bin/tgpt"]
            + path.split(separator: ":").map { "\($0)/tgpt" }
        guard let tgpt = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            fputs("tgpt is not installed. Install it with: brew install tgpt\n", stderr)
            exit(1)
        }
        let locale = Locale.current.identifier
        let prompt = "Answer only questions about macOS terminal commands. Respond in the language of the user's macOS locale (\(locale)). Use plain text without Markdown or code fences. Give a short explanation, one command on its own line, and what it does. If unrelated to macOS commands, say you only help with macOS commands. Never run a suggested command automatically. Question: \(question)"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tgpt)
        process.arguments = ["--provider", "pollinations", "--quiet", "--whole", prompt]
        do {
            try process.run()
            process.waitUntilExit()
            exit(process.terminationStatus)
        } catch {
            fputs("Unable to start tgpt: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    static func shellCommand(question: String) -> String {
        let executable = Bundle.main.executableURL?.path ?? CommandLine.arguments[0]
        return "\(shellQuote(executable)) --ask \(shellQuote(question))\r"
    }
}
