import AppKit
import SwiftUI

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // We handle settings via a custom window manager in SettingsView.swift
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSPanel!
    var clipboardManager = ClipboardManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Check for first run and enable Launch at Login
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: true)
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(clipboardManager: clipboardManager)

        // Create the window (panel)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.contentView = NSHostingView(rootView: contentView)
        panel.center()

        // Hide standard window buttons for a cleaner, modern look
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        // Set delegate to handle auto-hiding behavior
        panel.delegate = self

        self.window = panel

        // Setup HotKey
        HotKeyManager.shared.onTrigger = { [weak self] in
            self?.toggleWindow()
        }
        HotKeyManager.shared.start()

        // Start Clipboard Monitoring
        clipboardManager.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardManager.stopMonitoring()
    }

    func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            // Center on screen or near mouse could be an option, but center is predictable
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        // Automatically hide the window when it loses focus (mimics Windows + V behavior)
        // Check if we are opening the settings window, if so, maybe keep it?
        // For now, strict auto-hide is standard for this type of utility.
        if let panel = notification.object as? NSPanel, panel == self.window {
            panel.orderOut(nil)
        }
    }
}
