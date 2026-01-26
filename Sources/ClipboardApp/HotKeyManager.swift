import Carbon
import Cocoa

class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()

    @Published var shortcutString = "⌘ ⇧ V"

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerEntry: EventHandlerRef?

    // Default: Cmd + Shift + V (ANSI_V is 0x09)
    private(set) var currentKeyCode: UInt32 = UInt32(kVK_ANSI_V)
    private(set) var currentModifiers: UInt32 = UInt32(cmdKey | shiftKey)

    var onTrigger: (() -> Void)?

    private init() {
        // Restore from UserDefaults if available
        if UserDefaults.standard.object(forKey: "hotKeyKeyCode") != nil {
            self.currentKeyCode = UInt32(UserDefaults.standard.integer(forKey: "hotKeyKeyCode"))
            self.currentModifiers = UInt32(UserDefaults.standard.integer(forKey: "hotKeyModifiers"))
        }
        updateShortcutString()
    }

    func start() {
        registerHotKey(keyCode: currentKeyCode, modifiers: currentModifiers)
    }

    func updateHotKey(keyCode: UInt32, modifiers: UInt32) {
        self.currentKeyCode = keyCode
        self.currentModifiers = modifiers

        UserDefaults.standard.set(keyCode, forKey: "hotKeyKeyCode")
        UserDefaults.standard.set(modifiers, forKey: "hotKeyModifiers")

        registerHotKey(keyCode: keyCode, modifiers: modifiers)
        updateShortcutString()
    }

    private func registerHotKey(keyCode: UInt32, modifiers: UInt32) {
        unregisterHotKey()

        var hotKeyID = EventHotKeyID()
        // Unique signature: 'CBHM' (ClipBoard History Manager)
        hotKeyID.signature = OSType(0x4342_484D)
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // Define a C-compatible handler closure
        let handler: EventHandlerProcPtr = { _, _, _ -> OSStatus in
            DispatchQueue.main.async {
                HotKeyManager.shared.onTrigger?()
            }
            return noErr
        }

        // Install the event handler
        let status = InstallEventHandler(
            GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandlerEntry)
        if status != noErr {
            print("Error installing event handler: \(status)")
        }

        // Register the hotkey
        let regStatus = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if regStatus != noErr {
            print("Failed to register hotkey: \(regStatus)")
        }
    }

    private func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerEntry = eventHandlerEntry {
            RemoveEventHandler(eventHandlerEntry)
            self.eventHandlerEntry = nil
        }
    }

    private func updateShortcutString() {
        var parts: [String] = []
        if (currentModifiers & UInt32(cmdKey)) != 0 { parts.append("⌘") }
        if (currentModifiers & UInt32(controlKey)) != 0 { parts.append("⌃") }
        if (currentModifiers & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (currentModifiers & UInt32(shiftKey)) != 0 { parts.append("⇧") }

        parts.append(keyString(for: currentKeyCode))
        shortcutString = parts.joined(separator: " ")
    }

    private func keyString(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape: return "⎋"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return "Key(\(keyCode))"
        }
    }
}
