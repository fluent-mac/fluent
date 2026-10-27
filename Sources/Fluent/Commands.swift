import SwiftUI
import AppKit
import FluentCore

struct FluentCommands: Commands {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Test") { model.newTest() }
                .keyboardShortcut("n")
            Button("Repeat Test") { model.repeatTest() }
                .keyboardShortcut("r")
            Button("Custom Text…") { model.showCustomSheet = true }
            Divider()
            Button("Export History…") { model.exportCSV() }
        }

        CommandGroup(after: .toolbar) {
            Toggle("Show On-Screen Keyboard", isOn: $model.prefs.showKeyboard)
                .keyboardShortcut("k", modifiers: [.command, .option])
        }

        CommandGroup(after: .windowArrangement) {
            Toggle("Keep on Top", isOn: $model.prefs.floating)
        }

        CommandMenu("Go") {
            ForEach(Array(AppSection.allCases.prefix(10).enumerated()), id: \.element) { i, s in
                Button(s.title) { model.section = s }
                    .keyboardShortcut(KeyEquivalent(Character(i < 9 ? "\(i + 1)" : "0")), modifiers: [.command, .option])
            }
            Divider()
            ForEach(Array(AppSection.allCases.dropFirst(10))) { s in
                Button(s.title) { model.section = s }
            }
        }

        CommandMenu("Test") {
            modeItem(.time, "1")
            modeItem(.words, "2")
            modeItem(.sentences, "3")
            modeItem(.custom, "4")
            Divider()
            Menu("Length") {
                switch model.prefs.mode {
                case .time:
                    ForEach([15, 30, 60, 120], id: \.self) { n in
                        Toggle("\(n) Seconds", isOn: Binding(get: { model.prefs.timeLimit == n }, set: { _ in model.setTime(n) }))
                    }
                case .words:
                    ForEach([10, 25, 50, 100], id: \.self) { n in
                        Toggle("\(n) Words", isOn: Binding(get: { model.prefs.wordCount == n }, set: { _ in model.setWords(n) }))
                    }
                default:
                    Button("Fixed Length") {}.disabled(true)
                }
            }
            Divider()
            Toggle("Punctuation", isOn: $model.prefs.punctuation).disabled(!model.prefs.mode.usesWordList)
            Toggle("Numbers", isOn: $model.prefs.numbers).disabled(!model.prefs.mode.usesWordList)
            Toggle("Stop on Error", isOn: $model.prefs.strict)
            Toggle("Race Best Pace", isOn: $model.prefs.raceBest)
            Divider()
            Button("Practice Weak Keys") { model.startDrill() }
                .disabled(model.store.weakKeys.isEmpty)
        }

        CommandGroup(replacing: .appInfo) {
            Button("About Fluent") {
                NSApplication.shared.orderFrontStandardAboutPanel(options: [
                    .credits: NSAttributedString(string: "Keyboard, mouse, trackpad and hardware tools for the Mac."),
                ])
            }
        }

        CommandGroup(replacing: .help) {
            Button("Fluent Help") { openWindow(id: "help") }
                .keyboardShortcut("?")
            Button("Show Welcome") { model.showWelcome = true }
            Divider()
            Button("Shortcuts") { model.section = .shortcuts }
            Button("Open Keyboard Settings") { SystemSettings.open(SystemSettings.keyboard) }
            Button("Open Trackpad Settings") { SystemSettings.open(SystemSettings.trackpad) }
        }
    }

    private func modeItem(_ m: TestMode, _ key: KeyEquivalent) -> some View {
        Toggle(m.title, isOn: Binding(get: { model.prefs.mode == m }, set: { _ in model.setMode(m) }))
            .keyboardShortcut(key)
    }
}
