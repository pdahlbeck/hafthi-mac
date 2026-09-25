# Hafþi for Mac
<img width="1672" height="941" alt="57007fb1-e88d-46fa-b954-6b6d58689367" src="https://github.com/user-attachments/assets/feafbd72-97e5-4503-80d3-8039c6f449ea" />

A native macOS version of [Hafþi for Linux](https://github.com/pdahlbeck/hafthi), written in Swift and AppKit. [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) handles terminal emulation; Metal rendering is used when available, with a Core Graphics fallback.

## Download

Download [Hafþi 0.1.0 beta 18 for Apple Silicon](https://github.com/pdahlbeck/hafthi-mac/releases/tag/v0.1.0-beta.18). Unzip `Hafthi-0.1.0-beta.18-macOS-arm64.zip` and drag `Hafþi.app` to Applications. It requires macOS 13 or later. You do **not** need Xcode or build tools to run the download.

The beta is ad hoc signed, but not notarized with an Apple Developer ID. If macOS blocks the first launch, try opening the app, then choose **System Settings → Privacy & Security → Open Anyway** for Hafþi. You do not need to disable Gatekeeper for the whole Mac.

## Features

| Area | What the Mac app does |
| --- | --- |
| Terminal | Runs a real local shell in a macOS pseudo-terminal; ANSI colors, selection, scrollback and interactive full-screen programs. Commands run on your Mac. |
| Windows and input | Multiple resizable windows, copy, paste, select all, clear scrollback, a right-click menu, and Control + mouse wheel font zoom. Option remains available for characters such as å, ä and ö. |
| Appearance | Configurable font family and size, text/background/cursor colors, background opacity, terminal padding and scrollback length. Changes to these settings apply to open windows. |
| Images | Optional PNG, JPEG, WebP or animated GIF background, with **Off**, **Banner** and **Full image** modes. Banner keeps the image above the terminal text; Full image fills the window behind it. |
| Shell and prompt | Automatically uses Fish when installed; otherwise uses your normal login shell. Fish's startup message is hidden by default in Hafþi. Starship can be enabled automatically for Fish when installed. |
| Command help | Optional tgpt integration in Preferences and the right-click menu. The question goes to tgpt's online provider; suggested shell commands are displayed, not executed. |
| Ghost Tasks | Prefix a non-interactive command with `g` to run it quietly in the background. Check status with `g jobs` and read captured output with `g log ID`. |\n| Live dashboards | Optional Sampler integration opens a dedicated terminal window with a bundled example dashboard. Sampler itself is installed separately. |
| File manager | Optional Yazi integration opens a dedicated terminal window to browse files. Yazi is installed separately. |
| Text editor | Optional Micro integration opens a dedicated terminal window to edit files. Micro is installed separately. |

### Shortcuts

| Action | Shortcut |
| --- | --- |
| New window | ⌘ N |
| Preferences | ⌘ , |
| Copy / paste / select all | ⌘ C / ⌘ V / ⌘ A |
| Increase / decrease font size | ⌘ + / ⌘ − or Control + mouse wheel |
| Ask tgpt (when enabled) | Control + Shift + H |
| Interrupt a running command | Control + C |

The right-click menu also offers **Reset Font Size**, **Clear Scrollback** and **Edit Hafþi Config**. Closing the last window quits the app.

### Ghost Tasks

Use `g make -j4` to start a non-interactive task without mixing its output into your prompt. Run `g jobs` to check status, `g log ID` to read its output, `g follow ID` to watch it live (Ctrl+C stops watching), and `g clean` to remove completed logs. The start message gives you the ID. Quote pipelines or expressions: `g 'make && echo done'`. Tasks run in the directory where you started them. A small badge at the bottom right blinks between `{ö}` and `{-}` while tasks run, then disappears; a desktop notification announces completion. Logs are private to your account in `~/Library/Application Support/Hafthi/GhostTasks`. This `g` command is available inside Hafþi; run password prompts and interactive apps directly in the foreground.

### Optional Fish and Starship

Install [Fish](https://fishshell.com/) separately with `brew install fish` to make it Hafþi's preferred shell. The Fish switch in Preferences controls whether new windows automatically use it; when off, Hafþi opens your normal login shell. To show Fish's welcome message in new windows, turn it on in Preferences. Hiding the message affects only Fish sessions launched by Hafþi; it does not edit your Fish configuration.

Install [Starship](https://starship.rs/) separately with `brew install starship`. When Fish and Starship are both installed, new Fish windows use Starship by default. Preferences has a switch for Hafþi's automatic Starship initialization. If your `config.fish` already initializes Starship, Hafþi leaves that setup in place. The switch applies to new windows and does not change `config.fish`. With another login shell, follow [Starship's shell setup guide](https://starship.rs/guide/) instead. Neither Fish nor Starship is bundled in the app.

### Optional command help

Enable **Command help** in Preferences. Install [tgpt](https://github.com/aandrew-me/tgpt) separately with `brew install tgpt`, or click **Install tgpt…** to place that command at the terminal prompt and press Enter yourself. Type a macOS terminal question in Preferences and click **Ask tgpt**, or open the question field from the right-click menu. The answer appears in the terminal. Questions are sent to tgpt's online provider; Hafþi does not automatically run suggested commands.

### Optional Sampler dashboard

Install [Sampler](https://github.com/sqshq/sampler) yourself with `brew install sampler`. Open **Preferences → Integrations → Sampler**, enable it, and click **Open Sampler**. It opens in its own Hafþi window; the app menu and right-click menu also offer **Open Sampler…** while enabled. **Install Sampler…** types the Homebrew command into your current terminal without running it.

The first launch copies the included example dashboard to `~/Library/Application Support/Hafthi/sampler.yml`. **Edit dashboard config…** opens that file. Your edits survive app updates; **Restore default…** resets it only after confirmation. The example periodically runs local commands for CPU, memory, uptime and time, and checks GitHub response time. Review the YAML before running it, especially if you change its commands or destinations. The GitHub response alert uses `bc`; install it separately if you want that alert.

### Optional Micro editor

Install [Micro](https://github.com/micro-editor/micro) yourself with `brew install micro`. Open **Preferences → Integrations → Micro**, enable it, and click **Open Micro**. It opens an empty buffer in its own Hafþi window. The app menu and right-click menu also offer **Open Micro…** while enabled; the installation button only types the Homebrew command in the current terminal. You can also run `micro filename` directly in a shell. Hafþi does not change your default editor.

### Optional Yazi file manager

Install [Yazi](https://github.com/sxyazi/yazi) yourself with `brew install yazi`. Open **Preferences → Integrations → Yazi**, enable it, and click **Open Yazi**. It starts in your home directory in a dedicated Hafþi window. The app menu and right-click menu also offer **Open Yazi…** while enabled. **Install Yazi…** types the Homebrew command into your current terminal without running it. Image previews may be limited because Hafþi does not currently advertise a Yazi-supported image protocol. Yazi and its optional preview tools are not bundled with Hafþi.

## Preferences and configuration

Use **⌘ ,** to open Preferences. Its sidebar has **Appearance** (font, colors, opacity), **Terminal** (padding, scrollback), **Background** (image/GIF mode), and **Integrations**. The Fish, Starship, tgpt, Sampler, Yazi and Micro cards each have an on/off switch; click a card to open its detailed settings, installation instructions, and GitHub repository link. These optional tools are installed separately via Homebrew. Preferences are saved in `~/Library/Application Support/Hafthi/config.json`. You can open that file from **Edit Hafþi Config** in the right-click menu. Changes to the Fish and Starship startup settings take effect in new windows.

## Build from source

You need macOS 13 or later, an Apple Silicon Mac and Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/pdahlbeck/hafthi-mac.git
cd hafthi-mac
swift run --build-system native HafthiMac
```

To create a standalone app bundle locally:

```sh
bash build-app.sh
open build/Hafþi.app
```

## Port status

This is a macOS beta. The [Linux version](https://github.com/pdahlbeck/hafthi) uses a custom wgpu preferences interface and Wayland-specific transparency. The Mac app uses native AppKit preferences, macOS transparency and optional Metal rendering. Linux features still in development, such as split panes and **Open File Manager Here**, are not advertised as Mac features.

## License

Hafþi is MIT licensed. SwiftTerm is also MIT licensed; see its [license](https://github.com/migueldeicaza/SwiftTerm/blob/v1.19.0/LICENSE). Starship is installed by the user and is not included in Hafþi; it is [ISC licensed](https://github.com/starship/starship/blob/main/LICENSE).
