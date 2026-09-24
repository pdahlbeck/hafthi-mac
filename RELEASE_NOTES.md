Hafþi beta 12 for Apple Silicon Macs (macOS 13 or later).

- Download `Hafthi-0.1.0-beta.12-macOS-arm64.zip`, unzip it, and drag `Hafþi.app` to Applications. No Xcode or build tools are needed.
- Delay closing a terminal window until SwiftTerm's process-exit callback has returned, avoiding teardown during its cleanup when Sampler quits.
- Disconnect callbacks when a window is manually closed so a later process-exit notification cannot close it again.
- Keep the beta 11 fix that passes a standard macOS command search path to Sampler.
- Keep the beta 10 fix that loads the bundled dashboard configuration from the app's Resources directory.
- Add an optional Sampler card with an on/off control, installation guidance and a GitHub link in Preferences → Plugins.
- Install Sampler separately with `brew install sampler`. Enable it and open a dashboard in its own Hafþi window from Preferences or the app menu.
- Bundle an example dashboard configuration. It is copied to `~/Library/Application Support/Hafthi/sampler.yml` on first use and remains editable across app updates. Restore it from Preferences after confirmation.

This beta is ad hoc signed but not notarized with an Apple Developer ID. macOS may block it on first launch. After trying to open it, open System Settings → Privacy & Security → Open Anyway to approve this specific app.

Source code: https://github.com/pdahlbeck/hafthi-mac
