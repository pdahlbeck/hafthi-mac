# Hafþi for macOS

An experimental native macOS port of [Hafþi](https://github.com/pdahlbeck/hafthi), written in Swift and AppKit. It uses [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) for terminal emulation and optional Metal rendering.

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

Hafþi Mac supports ANSI colors, interactive full-screen applications, selection, scrollback, Command+N for a new window, Control+mouse wheel for font zoom, and a right-click menu. Preferences (Command+,) control font and colors, transparency, padding, scrollback, an optional image or GIF background, and whether Fish shows its startup greeting. The greeting is hidden by default inside Hafþi; other terminals and your Fish configuration are unaffected. Settings are saved in `~/Library/Application Support/Hafthi/config.json`.

Optional command help can be enabled in Preferences. [tgpt](https://github.com/aandrew-me/tgpt) can be installed with `brew install tgpt`; questions are sent to its online provider, and suggested commands are never executed for you.

## Build an app

```sh
bash build-app.sh
open build/HafthiMac.app
```

The locally built app is unsigned. For distributing it to other Macs, code signing and notarization will be needed.

## Status

This is a macOS port under development. The Linux GPU renderer's custom preferences design and Wayland transparency are not ported directly; the Mac version uses AppKit and optional Metal. The existing Linux version remains at [pdahlbeck/hafthi](https://github.com/pdahlbeck/hafthi).

## License

MIT

SwiftTerm is also MIT licensed; see its [LICENSE](https://github.com/migueldeicaza/SwiftTerm/blob/v1.19.0/LICENSE).
