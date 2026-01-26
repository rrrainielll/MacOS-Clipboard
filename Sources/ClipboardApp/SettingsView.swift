import Carbon
import SwiftUI

struct SettingsView: View {
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    @ObservedObject var launchAtLoginManager = LaunchAtLoginManager.shared
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: {
                    NSApplication.shared.keyWindow?.close()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // General Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("General")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Toggle(
                            "Launch at Login",
                            isOn: Binding(
                                get: { launchAtLoginManager.isEnabled },
                                set: { launchAtLoginManager.setLaunchAtLogin(enabled: $0) }
                            )
                        )
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .font(.body)
                    }

                    Divider()

                    // Shortcut Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Global Shortcut")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            Text("Toggle Clipboard:")
                            Spacer()
                            Button(action: {
                                isRecording = true
                            }) {
                                Text(isRecording ? "Press Keys..." : hotKeyManager.shortcutString)
                                    .frame(minWidth: 100)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        isRecording
                                            ? Color.accentColor
                                            : Color(NSColor.controlBackgroundColor)
                                    )
                                    .foregroundColor(isRecording ? .white : .primary)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        if isRecording {
                            Text("Press your desired key combination.\nPress Escape to cancel.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Default: ⌘ ⇧ V")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Links Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About & Links")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Link(destination: URL(string: "http://github.com/rrrainielll")!) {
                            HStack {
                                Image(systemName: "link")
                                Text("GitHub: @rrrainielll")
                            }
                            .font(.caption)
                        }

                        Link(
                            destination: URL(
                                string: "https://blog.dex-server.space/?post=macos-clipboard-app")!
                        ) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Read my blog post about this app")
                            }
                            .font(.caption)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("MacOS Clipboard Manager")
                            .font(.caption)
                        Text("Version 1.0.0")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .frame(width: 350, height: 350)
        .background(
            ShortcutRecorderView(isRecording: $isRecording) { keyCode, modifiers in
                hotKeyManager.updateHotKey(keyCode: keyCode, modifiers: modifiers)
                isRecording = false
            }
        )
    }
}

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onRecord: (UInt32, UInt32) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = RecordingNSView()
        view.onKeyEvent = { event in
            if isRecording {
                // Handle Escape key to cancel
                if event.keyCode == kVK_Escape {
                    isRecording = false
                    return true
                }

                // Check if a non-modifier key was pressed
                let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                if !isModifierOnly(event) {
                    let carbonModifiers = convertModifiers(modifierFlags)
                    onRecord(UInt32(event.keyCode), carbonModifiers)
                    return true
                }
            }
            return false
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    private func isModifierOnly(_ event: NSEvent) -> Bool {
        let modifiers: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62]
        return modifiers.contains(event.keyCode)
    }

    private func convertModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    class RecordingNSView: NSView {
        var onKeyEvent: ((NSEvent) -> Bool)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            if let onKeyEvent = onKeyEvent, onKeyEvent(event) {
                return
            }
            super.keyDown(with: event)
        }
    }
}
