Hafþi beta 3 for Apple Silicon Macs (macOS 13 or later).

- Download `Hafthi-0.1.0-beta.3-macOS-arm64.zip`, unzip it, and drag `Hafþi.app` to Applications. No Xcode or build tools are needed.
- Fish remains optional (`brew install fish`). Starship is now optional too (`brew install starship`): Hafþi uses it automatically for new Fish windows when installed. Turn it off in Preferences (⌘,) if you prefer another prompt. Neither tool is bundled with the app, and Hafþi does not edit your Fish configuration.
- Image and GIF backgrounds, Fish greeting control, and other existing Preferences remain available.

This beta is ad hoc signed but not notarized with an Apple Developer ID. macOS may block it on first launch. After trying to open it, open System Settings → Privacy & Security → Open Anyway to approve this specific app.

Source code: https://github.com/pdahlbeck/hafthi-mac
