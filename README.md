# Hafþi

An experimental native macOS port of [Hafþi](https://github.com/pdahlbeck/hafthi), written in Swift and AppKit. It uses [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) for terminal emulation and optional Metal rendering.

## Download for Apple Silicon

Download the latest beta from [GitHub Releases](https://github.com/pdahlbeck/hafthi-mac/releases). Unzip `Hafthi-0.1.0-beta.2-macOS-arm64.zip` and drag `Hafþi.app` to Applications. macOS 13 or later is required; Xcode and the Command Line Tools are **not** required to run the downloaded app.

This beta has not been notarized with an Apple Developer ID. If macOS blocks it the first time, try to open the app, then go to **System Settings → Privacy & Security → Open Anyway** to approve this app. There is no need to disable Gatekeeper for the whole Mac.

Fish is optional. Install it separately with `brew install fish` if you want to use it; otherwise Hafþi opens your normal login shell. Fish is not included in the download.

## Build from source

- macOS 13 or later
- Apple Silicon Mac
- Xcode Command Line Tools (`xcode-select --install`)

```sh
git clone https://github.com/pdahlbeck/hafthi-mac.git
cd hafthi-mac
swift run --build-system native HafthiMac
```

This opens a window with Fish if installed, or your normal login shell otherwise. The shell runs in a macOS pseudo-terminal and commands run on your Mac. Use Command+C and Command+V for copy and paste. Use Control+C to interrupt a command.

Hafþi supports ANSI colors, interactive full-screen applications, selection, scrollback, Command+N for a new window, Control+mouse wheel for font zoom, and a right-click menu. Preferences (Command+,) control font and colors, transparency, padding, scrollback, an optional image or GIF background, and whether Fish shows its startup greeting. The greeting is hidden by default inside Hafþi; other terminals and your Fish configuration are unaffected. Settings are saved in `~/Library/Application Support/Hafthi/config.json`.

Optional command help can be enabled in Preferences. [tgpt](https://github.com/aandrew-me/tgpt) can be installed with `brew install tgpt`; questions are sent to its online provider, and suggested commands are never executed for you.

## Build an app

```sh
bash build-app.sh
open build/Hafþi.app
```

The downloadable beta is ad hoc signed for integrity, but is not notarized with an Apple Developer ID.

## Status

This is a macOS port under development. The Linux GPU renderer's custom preferences design and Wayland transparency are not ported directly; the Mac version uses AppKit and optional Metal. The existing Linux version remains at [pdahlbeck/hafthi](https://github.com/pdahlbeck/hafthi).

## License

MIT

SwiftTerm is also MIT licensed; see its [LICENSE](https://github.com/migueldeicaza/SwiftTerm/blob/v1.19.0/LICENSE).
