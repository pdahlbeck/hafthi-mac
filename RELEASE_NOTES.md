Hafþi beta 21 for Apple Silicon Macs (macOS 13 or later).

- Download `Hafthi-0.1.0-beta.21-macOS-arm64.zip`, unzip it, and replace `Hafþi.app` in Applications. No Xcode or build tools are needed.
- Interactive commands such as `g brew upgrade` open a second Hafþi window for safe password prompts and package choices while your original terminal stays free.
- Ghost Tasks run without access to the terminal's keyboard or screen; interactive programs such as `yay` and `sudo` are rejected up front.
- Ghost Tasks use short IDs like `ghost1`, `ghost2`, etc. Older `job.*` logs remain accessible.
- Ghost Tasks show a small blinking `{ö}` / `{-}` badge in the bottom right while a task is running. The badge disappears when the last task completes.
- Run `g make -j4` to work in the background, `g jobs` to see its status, and `g log ID` to read captured output. Completion notifications are sent by macOS.
- Keep the optional tools section named **Integrations**.

This beta is ad hoc signed but not notarized with an Apple Developer ID. macOS may block it on first launch. After trying to open it, open System Settings → Privacy & Security → Open Anyway to approve this specific app.

Source code: https://github.com/pdahlbeck/hafthi-mac
