import SwiftUI

struct HelpView: View {
    private static let topics: [(String, String, String)] = [
        ("text.cursor", "Practice, Progress and Keys", "Typing tests with time, word and sentence modes. Progress charts every result and Keys shows which keys are slow or missed."),
        ("cursorarrow.click.2", "Click Speed and Reaction", "Count clicks or key presses over 1 to 30 seconds, and time how fast you react to a color change."),
        ("computermouse", "Mouse", "Check every button, the scroll wheel, the reporting rate and an estimate of the sensor DPI."),
        ("keyboard", "Keyboard", "Press keys to see their names and codes, how many register at once and whether any stick."),
        ("hand.draw", "Trackpad", "Seventeen gestures, one at a time, each with an animation and a check when you get it right."),
        ("command", "Shortcuts", "Learn the common Mac shortcuts one at a time, or search all of them."),
        ("checklist", "Mac Check", "Hardware, battery, storage, activation and management status, with a checklist and a report you can copy. Meant for checking a used Mac."),
        ("rectangle.split.3x3", "Trackpad Surface", "Drag over the whole trackpad to find areas that do not respond."),
        ("display", "Display Test", "Full-screen colors and patterns for finding dead pixels."),
        ("speaker.wave.2", "Audio and Camera", "Left and right speaker tones, a microphone level meter and a camera preview."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Fluent Help").font(.largeTitle.weight(.semibold))
                ForEach(Self.topics, id: \.1) { t in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: t.0).font(.title2).frame(width: 30).foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.1).font(.headline)
                            Text(t.2).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                Text("Go in the menu bar jumps to any screen with ⌥⌘1 to ⌥⌘0.").foregroundStyle(.secondary)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 520, minHeight: 480)
    }
}

struct MenuBarContent: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ForEach(AppSection.allCases) { s in
            Button(s.title) { show(s) }
        }
        Divider()
        Toggle("Keep on Top", isOn: $model.prefs.floating)
        Divider()
        Button("Quit Fluent") { NSApplication.shared.terminate(nil) }
    }

    private func show(_ s: AppSection) {
        openWindow(id: "main")
        NSApplication.shared.activate()
        model.section = s
    }
}
