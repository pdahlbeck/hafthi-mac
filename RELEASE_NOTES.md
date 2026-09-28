Hafþi beta 27 for Apple Silicon Macs (macOS 13 or later).

- Fix the Ghost Tasks icon so a click opens and closes the drawer. Only the window that owns a running task shows its clickable icon.
- Verify the icon's hit target and button action in the packaged macOS app during CI and release builds.
- Show a small animated pixel ghost in the top-right corner while a Ghost Task is running. Click it to open or close the task drawer, or use Control + G. It disappears when the last task finishes.
- Sign the packaged app in both CI and release builds, and verify the Apple Silicon executable and signature after unpacking the ZIP.
- Ghost Tasks run in a private background PTY within the original Hafþi window. Open or hide its drawer with Control + G, including when a command asks for a password or confirmation later.
- Use `ghost brew upgrade` or `ghost make -j4` to start a task without colliding with shell shortcuts named `g`. The shorter `g` remains available. In Hafþi Fish sessions it is bound to Ghost Tasks after your Fish configuration loads; your Git shortcut elsewhere is unchanged. In zsh, use `ghost` if `g` is already taken.
- Run `ghost jobs` to see tasks and `ghost log ghost1` to read captured output. One Ghost Task runs per window at a time.
- Download `Hafthi-0.1.0-beta.27-macOS-arm64.zip`, unzip it, and replace `Hafþi.app` in Applications. No Xcode or build tools are needed.

This beta is ad hoc signed but not notarized with an Apple Developer ID. macOS may block it on first launch. After trying to open it, open System Settings → Privacy & Security → Open Anyway to approve this specific app.

Source code: https://github.com/pdahlbeck/hafthi-mac
