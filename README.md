# Hafþi for macOS

An experimental native macOS port of [Hafþi](https://github.com/pdahlbeck/hafthi), written in Swift and AppKit. This repository starts with a working terminal prototype for Apple Silicon; the Linux renderer, preferences and full escape-sequence support are not yet ported.

## Requirements

- macOS 13 or later
- Apple Silicon Mac
- Xcode Command Line Tools (`xcode-select --install`)
- Optional: [Fish](https://fishshell.com/) (`brew install fish`). Hafþi uses your login shell if Fish is not installed.

## Run

```sh
git clone https://github.com/pdahlbeck/hafthi-mac.git
cd hafthi-mac
swift run --build-system native HafthiMac
```

This opens a window with Fish if installed, or your normal login shell otherwise. The shell runs in a macOS pseudo-terminal and commands run on your Mac. Use Command+C and Command+V for copy and paste. Use Control+C to interrupt a command.

## Build an app

```sh
bash build-app.sh
open build/HafthiMac.app
```

The locally built app is unsigned. For distributing it to other Macs, code signing and notarization will be needed.

## Status

This is a first macOS prototype. It currently renders shell text with AppKit rather than Hafþi's GPU renderer. Fish's prompt can redraw the input line, but terminal colors and full-screen programs such as vim are not yet correctly rendered. The existing Linux version remains at [pdahlbeck/hafthi](https://github.com/pdahlbeck/hafthi).

## License

MIT
