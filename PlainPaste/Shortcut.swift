import AppKit
import CoreGraphics
import Combine
import Foundation

struct Shortcut: Codable, Equatable {
    var keyCode: Int64
    var useCommand: Bool
    var useShift: Bool
    var useOption: Bool
    var useControl: Bool
    var useFunction: Bool

    static let defaultShortcut = Shortcut(
        keyCode: 9,
        useCommand: false,
        useShift: true,
        useOption: false,
        useControl: false,
        useFunction: true
    )

    init(keyCode: Int64, useCommand: Bool, useShift: Bool, useOption: Bool, useControl: Bool, useFunction: Bool) {
        self.keyCode = keyCode
        self.useCommand = useCommand
        self.useShift = useShift
        self.useOption = useOption
        self.useControl = useControl
        self.useFunction = useFunction
    }

    init(flags: CGEventFlags, keyCode: Int64) {
        self.keyCode = keyCode
        self.useCommand = flags.contains(.maskCommand)
        self.useShift = flags.contains(.maskShift)
        self.useOption = flags.contains(.maskAlternate)
        self.useControl = flags.contains(.maskControl)
        self.useFunction = flags.contains(.maskSecondaryFn)
    }

    var flags: CGEventFlags {
        var f: CGEventFlags = []
        if useCommand { f.insert(.maskCommand) }
        if useShift { f.insert(.maskShift) }
        if useOption { f.insert(.maskAlternate) }
        if useControl { f.insert(.maskControl) }
        if useFunction { f.insert(.maskSecondaryFn) }
        return f
    }

    func matches(flags: CGEventFlags, keyCode: Int64) -> Bool {
        guard keyCode == self.keyCode else { return false }
        guard useCommand == flags.contains(.maskCommand) else { return false }
        guard useShift == flags.contains(.maskShift) else { return false }
        guard useOption == flags.contains(.maskAlternate) else { return false }
        guard useControl == flags.contains(.maskControl) else { return false }
        guard useFunction == flags.contains(.maskSecondaryFn) else { return false }
        return true
    }

    var displayString: String {
        Shortcut.modifierSymbols(for: flags) + Shortcut.keyName(for: keyCode)
    }

    static func modifierSymbols(for flags: CGEventFlags) -> String {
        var result = ""
        if flags.contains(.maskSecondaryFn) { result += "fn+" }
        if flags.contains(.maskControl) { result += "⌃" }
        if flags.contains(.maskAlternate) { result += "⌥" }
        if flags.contains(.maskShift) { result += "⇧" }
        if flags.contains(.maskCommand) { result += "⌘" }
        return result
    }

    static func cgFlags(from nsFlags: NSEvent.ModifierFlags) -> CGEventFlags {
        var f: CGEventFlags = []
        if nsFlags.contains(.command) { f.insert(.maskCommand) }
        if nsFlags.contains(.shift) { f.insert(.maskShift) }
        if nsFlags.contains(.option) { f.insert(.maskAlternate) }
        if nsFlags.contains(.control) { f.insert(.maskControl) }
        if nsFlags.contains(.function) { f.insert(.maskSecondaryFn) }
        return f
    }

    // Standard macOS virtual keycodes (HIToolbox Events.h), covering the full
    // keyboard rather than just letters/numbers, since the recorder allows
    // binding any key.
    static func keyName(for keyCode: Int64) -> String {
        let map: [Int64: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T",
            0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9", 0x1A: "7", 0x1B: "-",
            0x1C: "8", 0x1D: "0", 0x1E: "]", 0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x24: "Return", 0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",", 0x2C: "/",
            0x2D: "N", 0x2E: "M", 0x2F: ".", 0x30: "Tab", 0x31: "Space", 0x32: "`", 0x33: "Delete",
            0x35: "Escape", 0x37: "Command", 0x38: "Shift", 0x39: "Caps Lock", 0x3A: "Option", 0x3B: "Control",
            0x3C: "Right Shift", 0x3D: "Right Option", 0x3E: "Right Control", 0x3F: "Fn",
            0x40: "F17", 0x41: "Keypad .", 0x43: "Keypad *", 0x45: "Keypad +", 0x47: "Keypad Clear",
            0x48: "Volume Up", 0x49: "Volume Down", 0x4A: "Mute",
            0x4B: "Keypad /", 0x4C: "Keypad Enter", 0x4E: "Keypad -",
            0x4F: "F18", 0x50: "F19", 0x51: "Keypad =",
            0x52: "Keypad 0", 0x53: "Keypad 1", 0x54: "Keypad 2", 0x55: "Keypad 3", 0x56: "Keypad 4",
            0x57: "Keypad 5", 0x58: "Keypad 6", 0x59: "Keypad 7", 0x5A: "F20", 0x5B: "Keypad 8", 0x5C: "Keypad 9",
            0x60: "F5", 0x61: "F6", 0x62: "F7", 0x63: "F3", 0x64: "F8", 0x65: "F9", 0x67: "F11",
            0x69: "F13", 0x6A: "F16", 0x6B: "F14", 0x6D: "F10", 0x6F: "F12", 0x71: "F15",
            0x72: "Help", 0x73: "Home", 0x74: "Page Up", 0x75: "Forward Delete", 0x76: "F4",
            0x77: "End", 0x78: "F2", 0x79: "Page Down", 0x7A: "F1",
            0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑"
        ]
        return map[keyCode] ?? "Key#\(keyCode)"
    }
}

final class ShortcutStore: ObservableObject {
    static let shared = ShortcutStore()
    private let defaultsKey = "PlainPasteShortcut"

    @Published var current: Shortcut {
        didSet { save() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(Shortcut.self, from: data) {
            current = decoded
        } else {
            current = Shortcut.defaultShortcut
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
