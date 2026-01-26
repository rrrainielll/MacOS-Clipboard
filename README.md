# MacOS Clipboard Manager

A lightweight, native macOS clipboard manager built with SwiftUI and Swift. Mimics the functionality of the Windows 10/11 Clipboard History (Windows + V), allowing you to view history, pin items, and paste selected entries.

## Features

- **Clipboard History**: Automatically records text and images copied to the clipboard.
- **Global Shortcut**: Press `Cmd + Shift + V` (default) to toggle the history window from anywhere.
- **Pinning**: Pin important items so they don't get deleted or pushed out by new copies.
- **Deduplication**: Automatically handles duplicate entries.
- **Modern UI**: Clean, native macOS interface using SwiftUI.
- **Customizable Shortcut**: Configure the global hotkey in Settings.

## Requirements

- macOS 14.0 (Sonoma) or later.
- Swift 5.9 or later.

## Building and Running

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/MacOS-Clipboard.git
   cd MacOS-Clipboard
   ```

2. **Build the project**:
   ```bash
   swift build -c release
   ```

3. **Run the application**:
   ```bash
   .build/release/ClipboardApp
   ```

   *Note: On first run, you may need to grant Accessibility permissions in System Settings -> Privacy & Security -> Accessibility if the app requests to control the computer (required for pasting into other apps).*

## Usage

1. **Copy** text or images as you normally would (`Cmd + C`).
2. Press `Cmd + Shift + V` to open the Clipboard History panel.
3. **Click** on an item to copy it back to the system clipboard (it will also close the panel so you can paste with `Cmd + V`).
4. **Right-click** or use the **menu** on an item to:
   - **Pin/Unpin**: Keep the item in history indefinitely.
   - **Delete**: Remove the specific item.
5. Click the **Trash** icon in the header to clear all unpinned items.
6. Click the **Gear** icon to open Settings and change the global shortcut.

## Project Structure

- `Sources/ClipboardApp/App.swift`: Application entry point and window management.
- `Sources/ClipboardApp/ClipboardManager.swift`: Core logic for monitoring and managing clipboard data.
- `Sources/ClipboardApp/HotKeyManager.swift`: Global hotkey handling using Carbon APIs.
- `Sources/ClipboardApp/ContentView.swift`: Main history list view.
- `Sources/ClipboardApp/SettingsView.swift`: Settings interface and shortcut recorder.

## License

MIT