import Foundation

/// Key plus modifiers
public struct KeyCombo: Equatable, Sendable {
    public var key: String
    public var control = false
    public var option = false
    public var shift = false
    public var command = false

    public init(key: String, control: Bool = false, option: Bool = false, shift: Bool = false, command: Bool = false) {
        self.key = key
        self.control = control
        self.option = option
        self.shift = shift
        self.command = command
    }

    private static let names: [String: String] = [
        "space": "space", "tab": "tab", "esc": "esc", "return": "return",
        "⌫": "delete", "←": "left", "→": "right", "↑": "up", "↓": "down",
    ]

    private static let shown: [String: String] = [
        "space": "Space", "tab": "Tab", "esc": "Esc", "return": "Return",
        "delete": "⌫", "forwarddelete": "⌦", "left": "←", "right": "→", "up": "↑", "down": "↓",
    ]

    /// US key codes
    private static let codes: [UInt16: String] = [
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v", 11: "b",
        12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2", 20: "3", 21: "4",
        22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "o",
        32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j", 39: "'", 40: "k", 41: ";", 42: "\\",
        43: ",", 44: "/", 45: "n", 46: "m", 47: ".", 50: "`",
        49: "space", 48: "tab", 53: "esc", 51: "delete", 36: "return", 117: "forwarddelete",
        123: "left", 124: "right", 125: "down", 126: "up",
        122: "f1", 120: "f2", 99: "f3", 118: "f4", 96: "f5", 97: "f6",
        98: "f7", 100: "f8", 101: "f9", 109: "f10", 103: "f11", 111: "f12",
    ]

    public init?(keyCode: UInt16, control: Bool, option: Bool, shift: Bool, command: Bool) {
        guard let k = Self.codes[keyCode] else { return nil }
        self.init(key: k, control: control, option: option, shift: shift, command: command)
    }

    /// Parses combo text
    public static func parse(_ text: String) -> KeyCombo? {
        guard !text.contains(" ") else { return nil }
        var combo = KeyCombo(key: "")
        var rest = Substring(text)
        var fn = false
        if rest.hasPrefix("fn") {
            fn = true
            rest = rest.dropFirst(2)
        }
        while let ch = rest.first, "⌃⌥⇧⌘".contains(ch) {
            switch ch {
            case "⌃": combo.control = true
            case "⌥": combo.option = true
            case "⇧": combo.shift = true
            default: combo.command = true
            }
            rest = rest.dropFirst()
        }
        guard !rest.isEmpty else { return nil }
        var key = rest.lowercased()
        key = names[key] ?? key
        if key == "?" {
            key = "/"
            combo.shift = true
        }
        if fn {
            guard key == "delete" else { return nil }
            key = "forwarddelete"
        }
        combo.key = key
        return combo
    }

    /// Keycap labels
    public var labels: [String] {
        var out: [String] = []
        if control { out.append("⌃") }
        if option { out.append("⌥") }
        if shift { out.append("⇧") }
        if command { out.append("⌘") }
        out.append(Self.shown[key] ?? key.uppercased())
        return out
    }
}

extension MacShortcut {
    public var combo: KeyCombo? { KeyCombo.parse(keys) }

    /// System-reserved check
    public var detectable: Bool { combo != nil && !Self.system.contains(keys) }

    private static let system: Set<String> = [
        "⇧⌘3", "⇧⌘4", "⇧⌘5", "⌘Space", "⌘Tab", "⌘`", "⌥⌘Esc", "⌃⌘Q", "⌃↑", "⌃↓", "⌃→", "⌃←", "F11",
    ]
}
