import SwiftUI
import FluentCore

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @State private var confirmReset = false
    @AppStorage("menuBarExtra") private var menuBarExtra = false

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                Form {
                    Section {
                        Slider(value: $model.prefs.textSize, in: 18...40, step: 2) {
                            Text("Text size")
                        } minimumValueLabel: {
                            Text("A").font(.caption)
                        } maximumValueLabel: {
                            Text("A").font(.title3)
                        }
                        Text("The quick brown fox")
                            .font(.system(size: model.prefs.textSize, weight: .medium, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    Section {
                        Picker("Keyboard layout", selection: $model.prefs.layout) {
                            ForEach(KeyboardLayout.allCases) { Text($0.title).tag($0) }
                        }
                        Toggle("Show on-screen keyboard", isOn: $model.prefs.showKeyboard)
                        Toggle("Play a click while typing", isOn: $model.prefs.sound)
                        Toggle("Show in menu bar", isOn: $menuBarExtra)
                    }
                    Section {
                        Stepper("Daily goal: \(model.prefs.dailyGoal) tests", value: $model.prefs.dailyGoal, in: 1...20)
                    } footer: {
                        Text("Home shows how many tests you finished today.")
                    }
                }
                .formStyle(.grouped)
            }
            Tab("Typing", systemImage: "keyboard") {
                Form {
                    Section {
                        Toggle("Stop on error", isOn: $model.prefs.strict)
                        Toggle("Race my best pace", isOn: $model.prefs.raceBest)
                    } footer: {
                        Text("Stop on error holds the cursor until you press the right key. Race my best pace underlines where your best result for the same test would be.")
                    }
                    Section {
                        Toggle("Punctuation", isOn: $model.prefs.punctuation)
                        Toggle("Numbers", isOn: $model.prefs.numbers)
                    } footer: {
                        Text("These apply to Time and Words tests.")
                    }
                }
                .formStyle(.grouped)
            }
            Tab("Data", systemImage: "externaldrive") {
                Form {
                    Section {
                        LabeledContent("Tests recorded", value: "\(store.results.count)")
                        Button("Export History…") { model.exportCSV() }
                        Button("Reset Statistics…", role: .destructive) { confirmReset = true }
                    }
                }
                .formStyle(.grouped)
            }
        }
        .scenePadding()
        .frame(width: 480, height: 330)
        .confirmationDialog("Reset all statistics?", isPresented: $confirmReset) {
            Button("Reset Statistics", role: .destructive) { store.reset() }
        } message: {
            Text("This removes your test history and key data. It can't be undone.")
        }
    }
}

struct CustomTextSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    private var clean: String { TextGenerator.normalize(draft) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Text").font(.title2.weight(.semibold))
            Text("Paste something to type. Line breaks become spaces.")
                .foregroundStyle(.secondary)
            TextEditor(text: $draft)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(minHeight: 180)
            HStack {
                Text("\(clean.count) characters")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel", role: .cancel) {
                    if model.prefs.mode == .custom && TextGenerator.normalize(model.prefs.customText).isEmpty {
                        model.prefs.mode = .time
                    }
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Start") {
                    model.prefs.customText = draft
                    model.prefs.mode = .custom
                    model.newTest()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(clean.count < 10)
            }
        }
        .padding(24)
        .frame(width: 520)
        .onAppear { draft = model.prefs.customText }
    }
}
