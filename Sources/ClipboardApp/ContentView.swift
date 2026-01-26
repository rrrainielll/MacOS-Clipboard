import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    openSettings()
                }) {
                    Image(systemName: "gear")
                }
                .help("Settings")
                .buttonStyle(.borderless)
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))

            Divider()

            // List
            if clipboardManager.history.isEmpty {
                VStack {
                    Spacer()
                    Text("No clipboard history")
                        .foregroundColor(.secondary)
                    Text("Copy something to see it here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                List {
                    ForEach(clipboardManager.history) { item in
                        ClipboardItemRow(
                            item: item,
                            onDelete: {
                                clipboardManager.delete(item)
                            },
                            onPin: {
                                clipboardManager.togglePin(for: item)
                            }
                        )
                        .padding(.vertical, 4)
                        .onTapGesture {
                            copyAndPaste(item)
                        }
                        .contextMenu {
                            Button(action: {
                                copyAndPaste(item)
                            }) {
                                Text("Paste")
                                Image(systemName: "doc.on.clipboard")
                            }

                            Button(action: {
                                clipboardManager.togglePin(for: item)
                            }) {
                                Text(item.isPinned ? "Unpin" : "Pin")
                                Image(systemName: item.isPinned ? "pin.slash" : "pin")
                            }

                            Button(action: {
                                clipboardManager.delete(item)
                            }) {
                                Text("Delete")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 350, height: 500)
    }

    private func copyAndPaste(_ item: ClipboardItem) {
        clipboardManager.copyToSystemClipboard(item)
        // Hide the application after selection to return focus to the previous app
        NSApplication.shared.hide(nil)

        // Trigger simulated paste
        clipboardManager.pasteToCurrentApplication()
    }

    private func openSettings() {
        SettingsWindowManager.shared.showSettings()
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onDelete: () -> Void
    let onPin: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top) {
            Group {
                if item.type == .text {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.textContent ?? "")
                            .lineLimit(3)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)

                        Text(timeString(from: item.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if item.type == .image {
                    VStack(alignment: .leading, spacing: 2) {
                        if let image = NSImage(data: item.content) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 100)
                                .cornerRadius(4)
                        } else {
                            Text("Image")
                                .italic()
                        }
                        Text(timeString(from: item.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            HStack(spacing: 12) {
                // Pin Button
                Button(action: onPin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(item.isPinned ? .accentColor : .secondary)
                }
                .buttonStyle(.borderless)
                // Show if pinned or hovering
                .opacity(item.isPinned || isHovering ? 1 : 0)

                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                // Only show on hover
                .opacity(isHovering ? 1 : 0)
            }
        }
        .padding(4)
        .contentShape(Rectangle())  // Ensure hover works on the whole row
        .onHover { hover in
            isHovering = hover
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    private var windowController: NSWindowController?

    func showSettings() {
        if windowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 220),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())

            windowController = NSWindowController(window: window)
        }

        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
