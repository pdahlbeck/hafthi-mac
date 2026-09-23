import AppKit
import UniformTypeIdentifiers

struct MacSettings: Codable {
    var fontSize = 15.0
    var opacity = 0.65
    var padding = 16.0
    var scrollback = 15_000
    var backgroundMode = "off" // off, banner, full
    var imagePath = ""

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

final class PreferencesWindow: NSWindowController {
    private var settings: MacSettings
    var onChange: ((MacSettings) -> Void)?
    private let fontValue = NSTextField(labelWithString: "")
    private let opacityValue = NSTextField(labelWithString: "")
    private let paddingValue = NSTextField(labelWithString: "")
    private let historyValue = NSTextField(labelWithString: "")
    private let imageName = NSTextField(labelWithString: "")

    init(settings: MacSettings) {
        self.settings = settings
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 410),
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

        let font = slider(value: settings.fontSize, min: 9, max: 40, action: #selector(changeFont(_:)))
        fontValue.stringValue = "\(Int(settings.fontSize)) pt"
        stack.addArrangedSubview(row("Font size", font, fontValue))

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

    private func changed() { onChange?(settings) }

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
}
