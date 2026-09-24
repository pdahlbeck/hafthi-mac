Hafþi beta 10 for Apple Silicon Macs (macOS 13 or later).

- Download `Hafthi-0.1.0-beta.10-macOS-arm64.zip`, unzip it, and drag `Hafþi.app` to Applications. No Xcode or build tools are needed.
- Fix the crash when opening Sampler in beta 9: Hafþi now loads the bundled dashboard configuration from the app's Resources directory.
- If the bundled file is missing, show a useful error instead of terminating the app.
- Add an optional Sampler card with an on/off control, installation guidance and a GitHub link in Preferences → Plugins.
- Install Sampler separately with `brew install sampler`. Enable it and open a dashboard in its own Hafþi window from Preferences or the app menu.
- Bundle an example dashboard configuration. It is copied to `~/Library/Application Support/Hafthi/sampler.yml` on first use and remains editable across app updates. Restore it from Preferences after confirmation.

This beta is ad hoc signed but not notarized with an Apple Developer ID. macOS may block it on first launch. After trying to open it, open System Settings → Privacy & Security → Open Anyway to approve this specific app.

Source code: https://github.com/pdahlbeck/hafthi-mac
