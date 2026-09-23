# Hafþi for macOS

An experimental native macOS port of [Hafþi](https://github.com/pdahlbeck/hafthi), written in Swift and AppKit. This repository starts with a working terminal prototype for Apple Silicon; the Linux renderer, preferences and full escape-sequence support are not yet ported.

## Requirements

- macOS 13 or later
- Apple Silicon Mac
- Xcode Command Line Tools (`xcode-select --install`)

## Run

```sh
git clone https://github.com/pdahlbeck/hafthi-mac.git
cd hafthi-mac
swift run HafthiMac
```

This opens a window with an interactive login shell. The terminal runs commands on your Mac. Use Command+C and Command+V for copy and paste.

## Build an app

```sh
bash build-app.sh
open build/HafthiMac.app
```

The locally built app is unsigned. For distributing it to other Macs, code signing and notarization will be needed.

## Status

This is a first macOS prototype. It currently renders shell text with AppKit rather than Hafþi's GPU renderer. Its escape sequence support, scrollback, keyboard mapping and resizing still need work before it can replace a daily terminal. The existing Linux version remains at [pdahlbeck/hafthi](https://github.com/pdahlbeck/hafthi).

## License

MIT
