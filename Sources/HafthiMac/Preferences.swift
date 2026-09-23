import AppKit
import UniformTypeIdentifiers

struct MacSettings: Codable {
    var fontFamily = "System Monospaced"
    var fontSize = 15.0
    var foreground = "#f0f2f5"
    var background = "#1a1f26"
    var cursor = "#ffffff"
    var opacity = 0.65
    var padding = 16.0
    var scrollback = 15_000
    var backgroundMode = "off" // off, banner, full
    var imagePath = ""
    var commandHelpEnabled = false
    // Optional so settings saved by earlier versions still decode correctly.
    var showFishGreeting: Bool? = nil

    static var url: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Hafthi/config.json")
    }

    static func load() -> MacSettings {
        guard let data = try? Data(contentsOf: url),
              let settings = try? JSONDecoder().decode(MacSettings.self, from: data) else {
            return MacSettings()
        }
        return settings
    }

    func save() {
        try? FileManager.default.createDirectory(at: Self.url.deletingLastPathComponent(),
                                                  withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self) { try? data.write(to: Self.url, options: .atomic) }
    }
}

extension NSColor {
    convenience init?(hafthiHex: String) {
        let text = hafthiHex.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((value >> 16) & 255) / 255,
                  green: CGFloat((value >> 8) & 255) / 255,
                  blue: CGFloat(value & 255) / 255, alpha: 1)
    }

    var hafthiHex: String {
        let color = usingColorSpace(.sRGB) ?? self
        return String(format: "#%02X%02X%02X", Int(color.redComponent * 255),
                      Int(color.greenComponent * 255), Int(color.blueComponent * 255))
    }
}

final class PreferencesWindow: NSWindowController {
    private var settings: MacSettings
    var onChange: ((MacSettings) -> Void)?
    var onAsk: ((String) -> Void)?
    var onInstall: (() -> Void)?
    private let fontValue = NSTextField(labelWithString: "")
    private let opacityValue = NSTextField(labelWithString: "")
    private let paddingValue = NSTextField(labelWithString: "")
    private let historyValue = NSTextField(labelWithString: "")
    private let imageName = NSTextField(labelWithString: "")
    private let questionInput = NSTextField(string: "")
    private let familyInput = NSTextField(string: "")

    init(settings: MacSettings) {
        self.settings = settings
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 780),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Hafþi Preferences"
        window.center()
        super.init(window: window)
        buildControls(in: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func refresh(_ settings: MacSettings) {
        self.settings = settings
        window?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        if let window { buildControls(in: window) }
    }

    private func buildControls(in window: NSWindow) {
        guard let content = window.contentView else { return }
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24)
        ])

        familyInput.stringValue = settings.fontFamily
        familyInput.placeholderString = "System Monospaced, Menlo, JetBrains Mono…"
        familyInput.target = self
        familyInput.action = #selector(changeFamily(_:))
        stack.addArrangedSubview(row("Font family", familyInput, nil))

        let font = slider(value: settings.fontSize, min: 9, max: 40, action: #selector(changeFont(_:)))
        fontValue.stringValue = "\(Int(settings.fontSize)) pt"
        stack.addArrangedSubview(row("Font size", font, fontValue))

        stack.addArrangedSubview(row("Text color", colorWell(settings.foreground, #selector(changeForeground(_:))), nil))
        stack.addArrangedSubview(row("Background color", colorWell(settings.background, #selector(changeBackgroundColor(_:))), nil))
        stack.addArrangedSubview(row("Cursor color", colorWell(settings.cursor, #selector(changeCursorColor(_:))), nil))

        let opacity = slider(value: settings.opacity, min: 0, max: 1, action: #selector(changeOpacity(_:)))
        opacityValue.stringValue = "\(Int(settings.opacity * 100))%"
        stack.addArrangedSubview(row("Background opacity", opacity, opacityValue))

        let padding = slider(value: settings.padding, min: 0, max: 50, action: #selector(changePadding(_:)))
        paddingValue.stringValue = "\(Int(settings.padding)) px"
        stack.addArrangedSubview(row("Padding", padding, paddingValue))

        let history = slider(value: Double(settings.scrollback), min: 100, max: 50_000,
                             action: #selector(changeHistory(_:)))
        historyValue.stringValue = "\(settings.scrollback) lines"
        stack.addArrangedSubview(row("Scrollback", history, historyValue))

        let modes = NSSegmentedControl(labels: ["Off", "Banner", "Full image"], trackingMode: .selectOne,
                                       target: self, action: #selector(changeBackground(_:)))
        modes.selectedSegment = ["off", "banner", "full"].firstIndex(of: settings.backgroundMode) ?? 0
        stack.addArrangedSubview(row("Image background", modes, nil))

        let choose = NSButton(title: "Choose image or GIF…", target: self, action: #selector(chooseImage(_:)))
        imageName.stringValue = settings.imagePath.isEmpty ? "No image selected" : URL(fileURLWithPath: settings.imagePath).lastPathComponent
        imageName.lineBreakMode = .byTruncatingMiddle
        stack.addArrangedSubview(row("Image", choose, imageName))

        let fishInfo = NSTextField(wrappingLabelWithString:
            "Fish is the friendly interactive shell. Type help in the terminal for instructions.")
        fishInfo.textColor = .secondaryLabelColor
        fishInfo.widthAnchor.constraint(equalToConstant: 480).isActive = true
        stack.addArrangedSubview(fishInfo)
        let greeting = NSButton(checkboxWithTitle: "Show fish welcome message in new windows",
                                target: self, action: #selector(toggleFishGreeting(_:)))
        greeting.state = settings.showFishGreeting == true ? .on : .off
        stack.addArrangedSubview(greeting)

        let help = NSButton(checkboxWithTitle: "Enable optional command help", target: self,
                            action: #selector(toggleHelp(_:)))
        help.state = settings.commandHelpEnabled ? .on : .off
        stack.addArrangedSubview(help)
        questionInput.placeholderString = "Ask about a macOS terminal command"
        questionInput.isEnabled = settings.commandHelpEnabled
        questionInput.widthAnchor.constraint(equalToConstant: 390).isActive = true
        stack.addArrangedSubview(questionInput)
        let ask = NSButton(title: "Ask tgpt", target: self, action: #selector(askQuestion(_:)))
        ask.isEnabled = settings.commandHelpEnabled
        let install = NSButton(title: "Install tgpt…", target: self, action: #selector(installTgpt(_:)))
        stack.addArrangedSubview(NSStackView(views: [ask, install]))
        let privacy = NSTextField(wrappingLabelWithString: "Questions go to tgpt's online provider. Suggested commands are never run automatically.")
        privacy.textColor = .secondaryLabelColor
        stack.addArrangedSubview(privacy)

        let note = NSTextField(wrappingLabelWithString: "Changes are saved to ~/Library/Application Support/Hafthi/config.json")
        note.textColor = .secondaryLabelColor
        stack.addArrangedSubview(note)
    }

    private func row(_ title: String, _ control: NSView, _ value: NSTextField?) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.widthAnchor.constraint(equalToConstant: 140).isActive = true
        control.widthAnchor.constraint(equalToConstant: 220).isActive = true
        let row = NSStackView(views: [label, control] + (value.map { [$0] } ?? []))
        row.orientation = .horizontal
        row.spacing = 10
        row.alignment = .centerY
        return row
    }

    private func slider(value: Double, min: Double, max: Double, action: Selector) -> NSSlider {
        NSSlider(value: value, minValue: min, maxValue: max, target: self, action: action)
    }

    private func colorWell(_ hex: String, _ action: Selector) -> NSColorWell {
        let well = NSColorWell(frame: NSRect(x: 0, y: 0, width: 220, height: 25))
        well.color = NSColor(hafthiHex: hex) ?? .white
        well.target = self
        well.action = action
        return well
    }

    private func changed() { onChange?(settings) }

    @objc private func changeFamily(_ sender: NSTextField) {
        settings.fontFamily = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        changed()
    }

    @objc private func changeForeground(_ sender: NSColorWell) {
        settings.foreground = sender.color.hafthiHex
        changed()
    }

    @objc private func changeBackgroundColor(_ sender: NSColorWell) {
        settings.background = sender.color.hafthiHex
        changed()
    }

    @objc private func changeCursorColor(_ sender: NSColorWell) {
        settings.cursor = sender.color.hafthiHex
        changed()
    }

    @objc private func changeFont(_ sender: NSSlider) {
        settings.fontSize = Double(Int(sender.doubleValue))
        fontValue.stringValue = "\(Int(settings.fontSize)) pt"
        changed()
    }

    @objc private func changeOpacity(_ sender: NSSlider) {
        settings.opacity = sender.doubleValue
        opacityValue.stringValue = "\(Int(settings.opacity * 100))%"
        changed()
    }

    @objc private func changePadding(_ sender: NSSlider) {
        settings.padding = Double(Int(sender.doubleValue))
        paddingValue.stringValue = "\(Int(settings.padding)) px"
        changed()
    }

    @objc private func changeHistory(_ sender: NSSlider) {
        settings.scrollback = max(100, (Int(sender.doubleValue) / 100) * 100)
        historyValue.stringValue = "\(settings.scrollback) lines"
        changed()
    }

    @objc private func changeBackground(_ sender: NSSegmentedControl) {
        settings.backgroundMode = ["off", "banner", "full"][max(0, sender.selectedSegment)]
        changed()
    }

    @objc private func chooseImage(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.imagePath = url.path
        if settings.backgroundMode == "off" { settings.backgroundMode = "full" }
        refresh(settings)
        changed()
    }

    func focusQuestion() {
        window?.makeFirstResponder(questionInput)
    }

    @objc private func toggleHelp(_ sender: NSButton) {
        settings.commandHelpEnabled = sender.state == .on
        refresh(settings)
        changed()
    }

    @objc private func toggleFishGreeting(_ sender: NSButton) {
        settings.showFishGreeting = sender.state == .on
        changed()
    }

    @objc private func askQuestion(_ sender: Any?) {
        let question = String(questionInput.stringValue.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard settings.commandHelpEnabled, !question.isEmpty else { return }
        onAsk?(question)
    }

    @objc private func installTgpt(_ sender: Any?) { onInstall?() }
}
