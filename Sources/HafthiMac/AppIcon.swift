import AppKit

enum HafthiIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 512, height: 512))
        image.lockFocus()
        let border = NSBezierPath(roundedRect: NSRect(x: 30, y: 30, width: 452, height: 452),
                                  xRadius: 102, yRadius: 102)
        NSGradient(starting: NSColor(srgbRed: 0.09, green: 0.14, blue: 0.18, alpha: 1),
                   ending: NSColor(srgbRed: 0.02, green: 0.03, blue: 0.04, alpha: 1))?
            .draw(in: border, angle: 45)
        NSColor(srgbRed: 0.28, green: 0.38, blue: 0.46, alpha: 1).setStroke()
        border.lineWidth = 4
        border.stroke()

        let text = NSMutableParagraphStyle()
        text.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Georgia", size: 335) ?? NSFont.systemFont(ofSize: 335),
            .foregroundColor: NSColor(srgbRed: 0.84, green: 0.91, blue: 0.96, alpha: 1),
            .paragraphStyle: text
        ]
        ("þ" as NSString).draw(in: NSRect(x: 50, y: 70, width: 412, height: 390),
                                withAttributes: attributes)
        image.unlockFocus()
        return image
    }
}
