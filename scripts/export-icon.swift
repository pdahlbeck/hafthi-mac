import AppKit

@main
struct ExportIcon {
    static func main() throws {
        guard CommandLine.arguments.count == 2,
              let tiff = HafthiIcon.make().tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not render the Hafþi app icon")
        }
        try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    }
}
