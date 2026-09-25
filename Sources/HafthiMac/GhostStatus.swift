import Foundation
import Darwin

enum GhostStatus {
    static func hasRunningTask() -> Bool {
        let state = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/Hafthi/GhostTasks", isDirectory: true)
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: state,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return false }

        return entries.contains { entry in
            guard entry.lastPathComponent.hasPrefix("job."),
                  (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                  !FileManager.default.fileExists(atPath: entry.appendingPathComponent("exit").path)
            else { return false }

            if let text = try? String(contentsOf: entry.appendingPathComponent("pid"), encoding: .utf8),
               let pid = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)), pid > 0 {
                return kill(pid, 0) == 0 || errno == EPERM
            }
            // g may have created the directory before the worker writes its PID.
            if let modified = try? entry.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                return Date().timeIntervalSince(modified) < 5
            }
            return false
        }
    }
}
