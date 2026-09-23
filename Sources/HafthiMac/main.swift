import AppKit
import Foundation

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
}

private final class TerminalSession {
    let view: TerminalView
    private let task = Process()
    private let input = Pipe()
    private let output = Pipe()
    private var buffer = ""
    private var escapeState = 0
    private var pendingUTF8 = Data()

    init(view: TerminalView) {
        self.view = view
        view.sendInput = { [weak self] data in
            guard let self else { return }
            try? self.input.fileHandleForWriting.write(contentsOf: data)
        }
    }

    func start() {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        task.executableURL = URL(fileURLWithPath: "/usr/bin/script")
        task.arguments = ["-q", "/dev/null", shell, "-l"]
        task.standardInput = input
        task.standardOutput = output
        task.standardError = output
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            DispatchQueue.main.async { [weak self] in self?.receive(data) }
        }
        do {
            try task.run()
        } catch {
            view.string = "Unable to start shell: \(error.localizedDescription)\n"
        }
    }

    func stop() {
        output.fileHandleForReading.readabilityHandler = nil
        if task.isRunning { task.terminate() }
    }

    private func receive(_ data: Data) {
        pendingUTF8.append(data)
        // Preserve an incomplete UTF-8 character across pipe reads.
        let bytes = [UInt8](pendingUTF8)
        var length = bytes.count
        while length > 0 && (bytes[length - 1] & 0xc0) == 0x80 { length -= 1 }
        if length > 0 {
            let first = bytes[length - 1]
            let expected = first < 0x80 ? 1 : first < 0xe0 ? 2 : first < 0xf0 ? 3 : 4
            if bytes.count - length + 1 < expected { length -= 1 }
        }
        guard length > 0, let decoded = String(bytes: bytes.prefix(length), encoding: .utf8) else { return }
        pendingUTF8 = Data(bytes.dropFirst(length))
        for character in decoded {
            switch escapeState {
            case 1:
                escapeState = character == "[" || character == "]" ? (character == "[" ? 2 : 3) : 0
            case 2:
                if character >= "@" && character <= "~" { escapeState = 0 }
            case 3:
                if character == "\u{7}" { escapeState = 0 }
                else if character == "\u{1b}" { escapeState = 4 }
            case 4:
                escapeState = character == "\\" ? 0 : 3
            default:
                switch character {
                case "\u{1b}": escapeState = 1
                case "\r":
                    if let newline = buffer.lastIndex(of: "\n") {
                        buffer.removeSubrange(buffer.index(after: newline)..<buffer.endIndex)
                    } else { buffer = "" }
                case "\u{8}", "\u{7f}":
                    if !buffer.isEmpty && buffer.last != "\n" { buffer.removeLast() }
                case "\u{7}": NSSound.beep()
                default: buffer.append(character)
                }
            }
        }
        // Keep memory use bounded for long-running sessions.
        if buffer.count > 200_000 { buffer = String(buffer.suffix(150_000)) }
        view.string = buffer
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
        session.start()
    }

    func windowWillClose(_ notification: Notification) {
        session?.stop()
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) { session?.stop() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
