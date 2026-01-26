# MacOS Clipboard Manager

A lightweight, native macOS clipboard manager built with SwiftUI. This application brings the functionality of the Windows Clipboard History (`Windows + V`) to macOS, allowing you to view clipboard history, pin items, and paste selected entries effortlessly.

## Features

- **Clipboard History**: Automatically tracks text and images copied to your clipboard.
- **Global Shortcut**: Press `Cmd + Shift + V` (default) to toggle the history panel from anywhere.
- **Auto-Paste**: Clicking an item automatically pastes it into your active application.
- **Pinning**: Pin important items to keep them indefinitely.
- **Inline Management**: Hover over items to Pin or Delete them instantly.
- **Launch at Login**: Option to automatically start the app when you log in.
- **Modern UI**: Clean, native macOS interface that feels like part of the system.
- **Customizable**: Change the global shortcut in Settings.

## Installation

### Using the Installer (Recommended)

1. Download the `ClipboardAppInstaller.pkg` file.
2. Double-click to run the installer.
3. Follow the prompts to install to your `/Applications` folder.
4. The app will launch automatically after installation.

*Note: You may need to grant Accessibility permissions (System Settings -> Privacy & Security -> Accessibility) to allow the app to simulate keystrokes for the auto-paste feature.*

## Usage

1. **Copy** text or images as usual (`Cmd + C`).
2. Press `Cmd + Shift + V` to open the Clipboard History.
3. **Click** an item to paste it immediately.
4. **Hover** over an item to see options:
   - 📌 **Pin**: Keep the item in history.
   - ❌ **Delete**: Remove the item.
5. Click the **Gear Icon** ⚙️ to access Settings:
   - Change the Global Shortcut.
   - Toggle "Launch at Login".
   - View project links.

## Development

### Requirements

- macOS 14.0 (Sonoma) or later.
- Swift 5.9 or later.
- Xcode Command Line Tools (`xcode-select --install`).

### Building from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/rrrainielll/MacOS-Clipboard.git
   cd MacOS-Clipboard
   ```

2. **Run the app**:
   ```bash
   swift run
   ```

### Creating the Installer

To generate a distributable `.pkg` installer:

1. Run the build script:
   ```bash
   ./build_pkg.sh
   ```

2. The installer will be created as `ClipboardAppInstaller.pkg` in the project root.

## Project Structure

- `Sources/ClipboardApp/App.swift`: Entry point and window management.
- `Sources/ClipboardApp/ClipboardManager.swift`: Core logic for monitoring clipboard changes.
- `Sources/ClipboardApp/HotKeyManager.swift`: Handling global shortcuts via Carbon APIs.
- `Sources/ClipboardApp/LaunchAtLoginManager.swift`: Manages auto-start functionality.
- `Sources/ClipboardApp/ContentView.swift`: Main UI implementation.
- `Sources/ClipboardApp/SettingsView.swift`: Settings window and shortcut recorder.

## About

- **Author**: Rainiel Montanez (@rrrainielll)
- **Blog**: [Read the blog post about this app](https://blog.dex-server.space/?post=macos-clipboard-app)

## License

MIT