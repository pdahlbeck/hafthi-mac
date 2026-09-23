import AppKit
import Darwin
import SwiftTerm

final class HafthiTerminalView: LocalProcessTerminalView {
    weak var owner: AppDelegate?

    override func menu(for event: NSEvent) -> NSMenu? { owner?.contextMenu(for: self) }

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            owner?.adjustFont(by: event.scrollingDeltaY > 0 ? 1 : -1)
        } else {
            super.scrollWheel(with: event)
        }
    }
}

final class TerminalWindow: NSWindow {
    let terminal: HafthiTerminalView
    private let imageView = NSImageView()
    private var edgeConstraints: [NSLayoutConstraint] = []
    private var topConstraint: NSLayoutConstraint!

    init(settings: MacSettings, owner: AppDelegate) {
        let frame = NSRect(x: 0, y: 0, width: 980, height: 640)
        terminal = HafthiTerminalView(frame: frame, font: nil,
                                      options: TerminalOptions(scrollback: max(100, settings.scrollback)))
        super.init(contentRect: frame,
                   styleMask: [.titled, .closable, .miniaturizable, .resizable],
                   backing: .buffered, defer: false)
        title = "Hafþi"
        center()
        isOpaque = false
        backgroundColor = .clear
        terminal.owner = owner

        guard let contentView else { return }
        contentView.wantsLayer = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        terminal.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(terminal)
        let left = terminal.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let right = terminal.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        let bottom = terminal.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        topConstraint = terminal.topAnchor.constraint(equalTo: contentView.topAnchor)
        edgeConstraints = [left, right, bottom]
        NSLayoutConstraint.activate(edgeConstraints + [topConstraint])
        apply(settings)
    }

    func apply(_ settings: MacSettings) {
        terminal.font = NSFont.monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
        terminal.nativeForegroundColor = NSColor(srgbRed: 0.94, green: 0.95, blue: 0.96, alpha: 1)
        terminal.nativeBackgroundColor = NSColor(srgbRed: 0.10, green: 0.12, blue: 0.15, alpha: 1)
        terminal.backgroundOpacity = CGFloat(settings.opacity)
        terminal.caretColor = .white
        terminal.selectedTextBackgroundColor = NSColor.systemBlue.withAlphaComponent(0.55)
        terminal.getTerminal().changeScrollback(max(100, settings.scrollback))

        let pad = CGFloat(settings.padding)
        edgeConstraints[0].constant = pad
        edgeConstraints[1].constant = -pad
        edgeConstraints[2].constant = -pad
        topConstraint.constant = pad + (settings.backgroundMode == "banner" ? 150 : 0)
        if settings.backgroundMode != "off", !settings.imagePath.isEmpty,
           let image = NSImage(contentsOfFile: settings.imagePath) {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.image = nil
            imageView.isHidden = true
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, LocalProcessTerminalViewDelegate {
    private var settings = MacSettings.load()
    private var windows: [ObjectIdentifier: TerminalWindow] = [:]
    private var preferences: PreferencesWindow?
    private weak var lastTerminal: HafthiTerminalView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.save()
        installMenu()
        openWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private static func preferredShell() -> String {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let candidates = ["/opt/homebrew/bin/fish", "/usr/local/bin/fish", "/opt/local/bin/fish"]
            + path.split(separator: ":").map { "\($0)/fish" }
        if let fish = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return fish
        }
        if let entry = getpwuid(getuid()), let shell = entry.pointee.pw_shell {
            let path = String(cString: shell)
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return "/bin/zsh"
    }

    @objc func openWindow(_ sender: Any?) {
        let window = TerminalWindow(settings: settings, owner: self)
        window.delegate = self
        windows[ObjectIdentifier(window)] = window
        let terminal = window.terminal
        lastTerminal = terminal
        terminal.processDelegate = self
        terminal.optionAsMetaKey = false // Option should still type å, ä, ö and other characters.
        terminal.linkReporting = .implicit
        do { try terminal.setUseMetal(true) } catch { /* CoreGraphics remains available. */ }
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(terminal)
        NSApp.activate(ignoringOtherApps: true)
        terminal.startProcess(executable: Self.preferredShell(), args: ["-l"],
                              currentDirectory: NSHomeDirectory())
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? TerminalWindow else { return }
        window.terminal.terminate()
        windows.removeValue(forKey: ObjectIdentifier(window))
    }

    func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
        source.window?.close()
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        source.window?.title = title.isEmpty ? "Hafþi" : "\(title) — Hafþi"
    }

    func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {}
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    private var activeTerminal: HafthiTerminalView? {
        (NSApp.keyWindow as? TerminalWindow)?.terminal ?? lastTerminal
    }

    func adjustFont(by amount: Int) {
        settings.fontSize = min(40, max(9, settings.fontSize + Double(amount)))
        settingsChanged(refreshPreferences: true)
    }

    private func settingsChanged(refreshPreferences: Bool = false) {
        settings.save()
        for window in windows.values { window.apply(settings) }
        if refreshPreferences { preferences?.refresh(settings) }
    }

    @objc private func largerFont(_ sender: Any?) { adjustFont(by: 1) }
    @objc private func smallerFont(_ sender: Any?) { adjustFont(by: -1) }
    @objc private func resetFont(_ sender: Any?) {
        settings.fontSize = 15
        settingsChanged(refreshPreferences: true)
    }
    @objc private func copySelection(_ sender: Any?) { activeTerminal?.copy(sender ?? self) }
    @objc private func pasteClipboard(_ sender: Any?) { activeTerminal?.paste(sender ?? self) }
    @objc private func selectTerminal(_ sender: Any?) { activeTerminal?.selectAll(sender) }
    @objc private func clearHistory(_ sender: Any?) { activeTerminal?.getTerminal().clearScrollback() }

    @objc private func showPreferences(_ sender: Any?) {
        if preferences == nil {
            let controller = PreferencesWindow(settings: settings)
            controller.onChange = { [weak self] newSettings in
                self?.settings = newSettings
                self?.settingsChanged()
            }
            preferences = controller
        }
        preferences?.showWindow(nil)
        preferences?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func editConfig(_ sender: Any?) { NSWorkspace.shared.open(MacSettings.url) }
    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }

    private func item(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func installMenu() {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Hafþi")
        appMenu.addItem(item("New Window", action: #selector(openWindow(_:)), key: "n"))
        appMenu.addItem(item("Preferences…", action: #selector(showPreferences(_:)), key: ","))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(item("Quit Hafþi", action: #selector(quit(_:)), key: "q"))
        bar.addItem(appItem)
        bar.setSubmenu(appMenu, for: appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(item("Copy", action: #selector(copySelection(_:)), key: "c"))
        editMenu.addItem(item("Paste", action: #selector(pasteClipboard(_:)), key: "v"))
        editMenu.addItem(item("Select All", action: #selector(selectTerminal(_:)), key: "a"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(item("Increase Font", action: #selector(largerFont(_:)), key: "+"))
        editMenu.addItem(item("Decrease Font", action: #selector(smallerFont(_:)), key: "-"))
        bar.addItem(editItem)
        bar.setSubmenu(editMenu, for: editItem)
        NSApp.mainMenu = bar
    }

    func contextMenu(for terminal: HafthiTerminalView) -> NSMenu {
        lastTerminal = terminal
        let menu = NSMenu(title: "Hafþi")
        menu.addItem(item("Copy", action: #selector(copySelection(_:))))
        menu.addItem(item("Paste", action: #selector(pasteClipboard(_:))))
        menu.addItem(item("Select All", action: #selector(selectTerminal(_:))))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(item("New Window", action: #selector(openWindow(_:))))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(item("Increase Font", action: #selector(largerFont(_:))))
        menu.addItem(item("Decrease Font", action: #selector(smallerFont(_:))))
        menu.addItem(item("Reset Font Size", action: #selector(resetFont(_:))))
        menu.addItem(item("Clear Scrollback", action: #selector(clearHistory(_:))))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(item("Preferences…", action: #selector(showPreferences(_:))))
        menu.addItem(item("Edit Hafþi Config", action: #selector(editConfig(_:))))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(item("Quit", action: #selector(quit(_:))))
        return menu
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
