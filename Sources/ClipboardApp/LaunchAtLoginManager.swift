import Foundation

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool = false

    private let label = "com.rainielmontanez.clipboardapp"

    private var launchAgentURL: URL? {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("LaunchAgents")
            .appendingPathComponent("\(label).plist")
    }

    init() {
        self.isEnabled = checkIsEnabled()
    }

    private func checkIsEnabled() -> Bool {
        guard let url = launchAgentURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func setLaunchAtLogin(enabled: Bool) {
        guard let url = launchAgentURL else { return }

        if enabled {
            createLaunchAgent(at: url)
        } else {
            removeLaunchAgent(at: url)
        }

        // Update state on main thread to ensure UI updates
        DispatchQueue.main.async {
            self.isEnabled = enabled
        }
    }

    private func createLaunchAgent(at url: URL) {
        // Use the current executable path so it works wherever the app is installed
        guard let executablePath = Bundle.main.executablePath else {
            print("Could not determine executable path")
            return
        }

        let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(executablePath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>ProcessType</key>
                <string>Interactive</string>
                <key>KeepAlive</key>
                <false/>
            </dict>
            </plist>
            """

        do {
            // Ensure LaunchAgents directory exists
            let directory = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true)
            }

            try plistContent.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to create launch agent: \(error)")
        }
    }

    private func removeLaunchAgent(at url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Failed to remove launch agent: \(error)")
        }
    }
}
