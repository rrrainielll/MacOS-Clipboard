import AppKit
import Carbon
import SwiftUI

enum ClipboardItemType: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    let type: ClipboardItemType
    let content: Data
    let textContent: String?
    let date: Date
    var isPinned: Bool

    init(type: ClipboardItemType, content: Data, textContent: String? = nil, isPinned: Bool = false)
    {
        self.type = type
        self.content = content
        self.textContent = textContent
        self.date = Date()
        self.isPinned = isPinned
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}

class ClipboardManager: ObservableObject {
    @Published var history: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int

    init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general

        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Try to read text
        if let str = pasteboard.string(forType: .string) {
            // Check if it's the same as the most recent item to avoid duplication loops
            if let last = history.first, last.type == .text, last.textContent == str {
                return
            }

            let data = str.data(using: .utf8) ?? Data()
            let newItem = ClipboardItem(type: .text, content: data, textContent: str)
            add(newItem)
            return
        }

        // Try to read image
        if pasteboard.canReadObject(forClasses: [NSImage.self], options: nil) {
            if let imageObjects = pasteboard.readObjects(forClasses: [NSImage.self], options: nil),
                let image = imageObjects.first as? NSImage,
                let tiffData = image.tiffRepresentation
            {

                // Compare with last item to avoid duplicates if possible, though comparing image data is expensive
                // Simple check: if last item is image and same size?
                if let last = history.first, last.type == .image,
                    last.content.count == tiffData.count
                {
                    // Good enough heuristic for now to prevent loop if we just pasted it
                    return
                }

                let newItem = ClipboardItem(type: .image, content: tiffData)
                add(newItem)
                return
            }
        }
    }

    func add(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // Deduplicate: If content exists, remove old one and add new to top (preserving pin status)
            var isPinned = item.isPinned

            if let index = self.history.firstIndex(where: {
                if $0.type != item.type { return false }
                if $0.type == .text { return $0.textContent == item.textContent }
                return $0.content == item.content
            }) {
                isPinned = self.history[index].isPinned
                self.history.remove(at: index)
            }

            var newItem = item
            newItem.isPinned = isPinned
            self.history.insert(newItem, at: 0)

            // Limit history size
            if self.history.count > 50 {
                if let lastUnpinnedIndex = self.history.lastIndex(where: { !$0.isPinned }) {
                    self.history.remove(at: lastUnpinnedIndex)
                }
            }
        }
    }

    func togglePin(for item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isPinned.toggle()
        }
    }

    func delete(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history.remove(at: index)
        }
    }

    func copyToSystemClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text:
            if let str = item.textContent {
                pasteboard.setString(str, forType: .string)
            }
        case .image:
            if let image = NSImage(data: item.content) {
                pasteboard.writeObjects([image])
            }
        }

        // We let the monitoring loop detect this change and move the item to the top of the history
    }

    func pasteToCurrentApplication() {
        // Delay slightly to allow the window to close and focus to return to the target application
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let source = CGEventSource(stateID: .hidSystemState)

            // kVK_ANSI_V = 0x09
            let vKeyCode: CGKeyCode = 0x09

            // Create Cmd+V press
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
            keyDown?.flags = .maskCommand

            // Create Cmd+V release
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
            keyUp?.flags = .maskCommand

            // Post events
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}
