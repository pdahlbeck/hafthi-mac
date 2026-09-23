Hafþi beta for Apple Silicon Macs (macOS 13 or later). The downloaded app is now named `Hafþi.app`.

- Download `Hafthi-0.1.0-beta.2-macOS-arm64.zip`, unzip it, and drag `Hafþi.app` to Applications. No Xcode or build tools are needed. If you installed beta 1, remove its old `HafthiMac.app` from Applications so you don't have two copies.
- Fish is optional. Install it separately with `brew install fish` if you want Hafþi to use it; otherwise Hafþi uses your normal login shell.
- Choose an image or GIF in Preferences (⌘,). Banner and full-window modes are available. Fish's startup message is hidden by default.

This beta is ad hoc signed but not notarized with an Apple Developer ID. macOS may block it on first launch. After trying to open it, open System Settings → Privacy & Security → Open Anyway to approve this specific app. Do not disable Gatekeeper system-wide.

Source code: https://github.com/pdahlbeck/hafthi-mac
