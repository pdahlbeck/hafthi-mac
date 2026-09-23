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
    var useStarship: Bool? = nil

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
    private enum Page: Int, CaseIterable {
        case appearance, terminal, background, plugins

        var title: String {
            switch self {
            case .appearance: return "Appearance"
            case .terminal: return "Terminal"
            case .background: return "Background"
            case .plugins: return "Plugins"
            }
        }
    }

    private var settings: MacSettings
    private var selectedPage: Page = .appearance
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
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 530),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Hafþi · Preferences"
        window.appearance = NSAppearance(named: .darkAqua)
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
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.18, alpha: 1).cgColor

        let sidebar = NSView()
        sidebar.wantsLayer = true
        sidebar.layer?.backgroundColor = NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.22, alpha: 1).cgColor
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(sidebar)

        let navigation = NSStackView()
        navigation.orientation = .vertical
        navigation.alignment = .leading
        navigation.spacing = 8
        navigation.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(navigation)

        let brand = NSTextField(labelWithString: "Hafþi")
        brand.font = .boldSystemFont(ofSize: 19)
        navigation.addArrangedSubview(brand)
        navigation.setCustomSpacing(24, after: brand)
        for page in Page.allCases {
            let button = NSButton(title: page.title, target: self, action: #selector(selectPage(_:)))
            button.tag = page.rawValue
            button.alignment = .left
            button.bezelStyle = .rounded
            button.isBordered = page == selectedPage
            button.font = .systemFont(ofSize: 13, weight: page == selectedPage ? .semibold : .regular)
            button.widthAnchor.constraint(equalToConstant: 160).isActive = true
            navigation.addArrangedSubview(button)
        }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 11
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            sidebar.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            sidebar.topAnchor.constraint(equalTo: content.topAnchor),
            sidebar.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 192),
            navigation.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 16),
            navigation.topAnchor.constraint(equalTo: sidebar.topAnchor, constant: 26),
            stack.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 26),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -20)
        ])

        let heading = NSTextField(labelWithString: selectedPage.title)
        heading.font = .boldSystemFont(ofSize: 22)
        stack.addArrangedSubview(heading)
        stack.setCustomSpacing(21, after: heading)

        switch selectedPage {
        case .appearance: buildAppearance(in: stack)
        case .terminal: buildTerminal(in: stack)
        case .background: buildBackground(in: stack)
        case .plugins: buildPlugins(in: stack)
        }
    }

    @objc private func selectPage(_ sender: NSButton) {
        guard let page = Page(rawValue: sender.tag), page != selectedPage else { return }
        selectedPage = page
        refresh(settings)
    }

    private func buildAppearance(in stack: NSStackView) {
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
    }

    private func buildTerminal(in stack: NSStackView) {
        let padding = slider(value: settings.padding, min: 0, max: 50, action: #selector(changePadding(_:)))
        paddingValue.stringValue = "\(Int(settings.padding)) px"
        stack.addArrangedSubview(row("Padding", padding, paddingValue))

        let history = slider(value: Double(settings.scrollback), min: 100, max: 50_000,
                             action: #selector(changeHistory(_:)))
        historyValue.stringValue = "\(settings.scrollback) lines"
        stack.addArrangedSubview(row("Scrollback", history, historyValue))
        stack.addArrangedSubview(detail("Changes are saved to ~/Library/Application Support/Hafthi/config.json"))
    }

    private func buildBackground(in stack: NSStackView) {
        let modes = NSSegmentedControl(labels: ["Off", "Banner", "Full image"], trackingMode: .selectOne,
                                       target: self, action: #selector(changeBackground(_:)))
        modes.selectedSegment = ["off", "banner", "full"].firstIndex(of: settings.backgroundMode) ?? 0
        stack.addArrangedSubview(row("Image background", modes, nil))

        let choose = NSButton(title: "Choose image or GIF…", target: self, action: #selector(chooseImage(_:)))
        imageName.stringValue = settings.imagePath.isEmpty ? "No image selected" : URL(fileURLWithPath: settings.imagePath).lastPathComponent
        imageName.lineBreakMode = .byTruncatingMiddle
        stack.addArrangedSubview(row("Image", choose, imageName))
    }

    private func buildPlugins(in stack: NSStackView) {
        stack.addArrangedSubview(section("Fish · shell"))
        stack.addArrangedSubview(detail("Uses Fish automatically when installed. Open a new window to switch shells."))
        let greeting = NSButton(checkboxWithTitle: "Show fish welcome message in new windows",
                                target: self, action: #selector(toggleFishGreeting(_:)))
        greeting.state = settings.showFishGreeting == true ? .on : .off
        stack.addArrangedSubview(greeting)

        stack.addArrangedSubview(section("Starship · prompt"))
        stack.addArrangedSubview(detail("Optional Fish prompt. Install separately with brew install starship."))
        let starship = NSButton(checkboxWithTitle: "Use Starship in new Fish windows when installed",
                                target: self, action: #selector(toggleStarship(_:)))
        starship.state = settings.useStarship != false ? .on : .off
        stack.addArrangedSubview(starship)

        stack.addArrangedSubview(section("tgpt · command help"))
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
        stack.addArrangedSubview(detail("Questions go to tgpt's online provider. Suggested commands are never run automatically."))
    }

    private func section(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }

    private func detail(_ message: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: message)
        label.textColor = .secondaryLabelColor
        label.widthAnchor.constraint(equalToConstant: 480).isActive = true
        return label
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
        if selectedPage != .plugins {
            selectedPage = .plugins
            refresh(settings)
        }
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

    @objc private func toggleStarship(_ sender: NSButton) {
        settings.useStarship = sender.state == .on
        changed()
    }

    @objc private func askQuestion(_ sender: Any?) {
        let question = String(questionInput.stringValue.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard settings.commandHelpEnabled, !question.isEmpty else { return }
        onAsk?(question)
    }

    @objc private func installTgpt(_ sender: Any?) { onInstall?() }
}
