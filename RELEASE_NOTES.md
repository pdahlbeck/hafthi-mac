Hafþi beta 17 for Apple Silicon Macs (macOS 13 or later).

- Download `Hafthi-0.1.0-beta.17-macOS-arm64.zip`, unzip it, and replace `Hafþi.app` in Applications. No Xcode or build tools are needed.
- Add Ghost Tasks: run `g make -j4` to work in the background, `g jobs` to see its status, and `g log ID` to read captured output. Completion notifications are sent by macOS.
- Keep the optional tools section named **Integrations**.

This beta is ad hoc signed but not notarized with an Apple Developer ID. macOS may block it on first launch. After trying to open it, open System Settings → Privacy & Security → Open Anyway to approve this specific app.

Source code: https://github.com/pdahlbeck/hafthi-mac
