import AppKit
import Darwin
import Foundation
import PTYSupport

private final class TerminalView: NSTextView {
    var sendInput: ((Data) -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            super.keyDown(with: event)
            return
        }

        let key: String
        switch event.keyCode {
        case 36, 76: key = "\r"  // Return
        case 51: key = "\u{7f}"  // Delete
        case 48: key = "\t"      // Tab
        case 53: key = "\u{1b}"  // Escape
        case 123: key = "\u{1b}[D"
        case 124: key = "\u{1b}[C"
        case 125: key = "\u{1b}[B"
        case 126: key = "\u{1b}[A"
        default:
            guard let characters = event.characters, !characters.isEmpty else { return }
            key = characters
        }
        sendInput?(Data(key.utf8))
    }

    override func paste(_ sender: Any?) {
        guard let value = NSPasteboard.general.string(forType: .string) else { return }
        sendInput?(Data(value.replacingOccurrences(of: "\n", with: "\r").utf8))
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "v" {
            paste(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

private final class TerminalSession {
    let view: TerminalView
    private var masterFD: Int32 = -1
    private var childPID: pid_t = -1
    private let inputQueue = DispatchQueue(label: "HafthiMac.PTYInput")
    private var screen = TerminalScreen()
    private var pendingUTF8 = Data()
    private var rows: UInt16 = 24
    private var columns: UInt16 = 80

    init(view: TerminalView) {
        self.view = view
        view.sendInput = { [weak self] data in
            self?.send(data)
        }
    }

    func start() {
        let shell = Self.preferredShell()
        // Fish needs a real interactive terminal for its prompt and suggestions.
        setenv("TERM", "xterm-256color", 1)
        setenv("COLORTERM", "truecolor", 1)
        let home = NSHomeDirectory()
        var fd: Int32 = -1
        let pid = shell.withCString { shellPath in
            home.withCString { homePath in
                hafthi_spawn_shell(shellPath, homePath, &fd, columns, rows)
            }
        }
        guard pid > 0 else {
            view.string = "Unable to start \(shell): \(String(cString: strerror(errno)))\n"
            return
        }
        masterFD = fd
        childPID = pid
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.readOutput(fd: fd, child: pid)
        }
    }

    private static func preferredShell() -> String {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let candidates = ["/opt/homebrew/bin/fish", "/usr/local/bin/fish", "/opt/local/bin/fish"]
            + path.split(separator: ":").map { "\($0)/fish" }
        if let fish = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return fish
        }
        let loginShell: String?
        if let entry = getpwuid(getuid()), let shell = entry.pointee.pw_shell {
            loginShell = String(cString: shell)
        } else {
            loginShell = nil
        }
        let fallback = loginShell ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        return FileManager.default.isExecutableFile(atPath: fallback) ? fallback : "/bin/zsh"
    }

    private func send(_ data: Data) {
        guard masterFD >= 0 else { return }
        let fd = masterFD
        inputQueue.async {
            data.withUnsafeBytes { raw in
                guard let base = raw.baseAddress else { return }
                var offset = 0
                while offset < raw.count {
                    let written = Darwin.write(fd, base.advanced(by: offset), raw.count - offset)
                    if written < 0 && errno == EINTR { continue }
                    if written <= 0 { break }
                    offset += written
                }
            }
        }
    }

    func resize(columns: Int, rows: Int) {
        let newColumns = UInt16(clamping: max(1, columns))
        let newRows = UInt16(clamping: max(1, rows))
        guard newColumns != self.columns || newRows != self.rows else { return }
        self.columns = newColumns
        self.rows = newRows
        screen.resize(columns: Int(newColumns))
        if masterFD >= 0 { _ = hafthi_resize_pty(masterFD, newColumns, newRows) }
    }

    private func readOutput(fd: Int32, child: pid_t) {
        var bytes = [UInt8](repeating: 0, count: 8192)
        while true {
            let count = bytes.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress, $0.count) }
            if count < 0 && errno == EINTR { continue }
            if count <= 0 { break }
            let data = Data(bytes.prefix(count))
            DispatchQueue.main.async { [weak self] in self?.receive(data) }
        }
        var status: Int32 = 0
        _ = waitpid(child, &status, 0)
        DispatchQueue.main.async { [weak self] in
            guard let self, self.childPID == child else { return }
            self.childPID = -1
            self.inputQueue.async { _ = Darwin.close(fd) }
            self.masterFD = -1
        }
    }

    func stop() {
        if childPID > 0 { _ = kill(childPID, SIGHUP); childPID = -1 }
        if masterFD >= 0 {
            let fd = masterFD
            masterFD = -1
            inputQueue.async { _ = Darwin.close(fd) }
        }
    }

    private func receive(_ data: Data) {
        pendingUTF8.append(data)
        guard !pendingUTF8.isEmpty else { return }
        // Preserve an incomplete UTF-8 character across PTY reads.
        let bytes = [UInt8](pendingUTF8)
        var lead = bytes.count - 1
        while lead > 0 && (bytes[lead] & 0xc0) == 0x80 { lead -= 1 }
        let first = bytes[lead]
        let expected = first < 0x80 ? 1 : first < 0xe0 ? 2 : first < 0xf0 ? 3 : 4
        let length = bytes.count - lead < expected ? lead : bytes.count
        guard length > 0 else { return }
        let decoded = String(decoding: bytes.prefix(length), as: UTF8.self)
        pendingUTF8 = Data(bytes.dropFirst(length))
        screen.consume(decoded)
        view.string = screen.text
        view.scrollToEndOfDocument(nil)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private var session: TerminalSession?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 590),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hafþi"
        window.center()
        window.delegate = self

        let scroll = NSScrollView(frame: window.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        let view = TerminalView(frame: scroll.bounds)
        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = NSColor(calibratedRed: 0.11, green: 0.13, blue: 0.16, alpha: 1)
        view.textColor = .white
        view.font = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        view.textContainerInset = NSSize(width: 16, height: 16)
        view.autoresizingMask = [.width]
        scroll.documentView = view
        window.contentView?.addSubview(scroll)

        let session = TerminalSession(view: view)
        self.session = session
        self.window = window
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSApp.activate(ignoringOtherApps: true)
        updateTerminalSize()
        session.start()
    }

    func windowDidResize(_ notification: Notification) { updateTerminalSize() }

    private func updateTerminalSize() {
        guard let window, let session, let view = session.view.font else { return }
        let cellWidth = ("M" as NSString).size(withAttributes: [.font: view]).width
        let lineHeight = session.view.layoutManager?.defaultLineHeight(for: view) ?? view.pointSize * 1.2
        let size = window.contentView?.bounds.size ?? .zero
        let insets = session.view.textContainerInset
        let columns = Int((size.width - 2 * insets.width - 20) / max(1, cellWidth))
        let rows = Int((size.height - 2 * insets.height) / max(1, lineHeight))
        session.resize(columns: max(1, columns), rows: max(1, rows))
    }

    func windowWillClose(_ notification: Notification) {
        session?.stop()
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) { session?.stop() }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
