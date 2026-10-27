import SwiftUI
import AppKit

struct KeyboardTestView: View {
    @State private var held: [UInt16: String] = [:]
    @State private var seen: [UInt16: String] = [:]
    @State private var last = ""
    @State private var lastCode: UInt16?
    @State private var repeats = 0
    @State private var most = 0

    private static let names: [UInt16: String] = [
        36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Esc", 76: "Enter",
        117: "Forward Delete", 115: "Home", 119: "End", 116: "Page Up", 121: "Page Down",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        54: "Right ⌘", 55: "Left ⌘", 56: "Left ⇧", 60: "Right ⇧", 58: "Left ⌥", 61: "Right ⌥",
        59: "Left ⌃", 62: "Right ⌃", 63: "fn", 57: "Caps Lock",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    private static let modifiers: [UInt16: NSEvent.ModifierFlags] = [
        54: .command, 55: .command, 56: .shift, 60: .shift, 58: .option, 61: .option,
        59: .control, 62: .control, 63: .function, 57: .capsLock,
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .frame(maxWidth: 600, minHeight: 190, maxHeight: 190)
                    .overlay {
                        VStack(spacing: 6) {
                            Text(last.isEmpty ? "Press any key" : last)
                                .font(.system(size: 56, weight: .semibold, design: .rounded))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            if let c = lastCode {
                                Text("Key code \(c)" + (repeats > 0 ? ", repeated \(repeats) times" : ""))
                                    .foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                        .padding()
                    }
                    .overlay(EventCapture(handlers: handlers))
                    .accessibilityLabel("Keyboard test area")

                HStack(spacing: 56) {
                    stat("Held now", "\(held.count)")
                    stat("Most at once", "\(most)")
                    stat("Keys tested", "\(seen.count)")
                }

                if !held.isEmpty { chips("Held", held.values.sorted(), strong: true) }
                if !seen.isEmpty { chips("Tested", seen.values.sorted(), strong: false) }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Keyboard")
        .toolbar {
            ToolbarItem { Button("Reset") { reset() } }
        }
        .onDisappear { held = [:] }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 40, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(title).font(.callout).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func chips(_ title: String, _ names: [String], strong: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(Array(names.enumerated()), id: \.offset) { _, n in
                    Text(n)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(strong ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .frame(maxWidth: 600, alignment: .leading)
    }

    private func name(_ e: NSEvent) -> String {
        if let n = Self.names[e.keyCode] { return n }
        if let c = e.charactersIgnoringModifiers?.uppercased(), !c.isEmpty { return c }
        return "Key \(e.keyCode)"
    }

    private var handlers: InputHandlers {
        var h = InputHandlers()
        h.key = { e, down in
            if down {
                if e.isARepeat { repeats += 1 } else { repeats = 0 }
                press(e)
            } else {
                held[e.keyCode] = nil
            }
        }
        h.flags = { e in
            guard let flag = Self.modifiers[e.keyCode] else { return }
            if e.modifierFlags.contains(flag) { repeats = 0; press(e) } else { held[e.keyCode] = nil }
        }
        return h
    }

    private func press(_ e: NSEvent) {
        let n = name(e)
        held[e.keyCode] = n
        seen[e.keyCode] = n
        last = n
        lastCode = e.keyCode
        most = max(most, held.count)
    }

    private func reset() {
        held = [:]
        seen = [:]
        last = ""
        lastCode = nil
        repeats = 0
        most = 0
    }
}
