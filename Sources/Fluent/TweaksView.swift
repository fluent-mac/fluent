import SwiftUI

struct TweaksView: View {
    @EnvironmentObject var model: AppModel

    private func ms(_ key: String) -> String {
        guard let v = UserDefaults.standard.object(forKey: key) as? Int else { return "System default" }
        return "\(v * 15) ms"
    }

    private func number(_ key: String) -> String {
        guard let v = UserDefaults.standard.object(forKey: key) as? Double else { return "System default" }
        return String(format: "%.2f", v)
    }

    private var natural: String {
        guard let v = UserDefaults.standard.object(forKey: "com.apple.swipescrolldirection") as? Bool else { return "On" }
        return v ? "On" : "Off"
    }

    var body: some View {
        Form {
            Section("Open in System Settings") {
                pane("Trackpad", "hand.draw", SystemSettings.trackpad)
                pane("Mouse", "computermouse", SystemSettings.mouse)
                pane("Keyboard", "keyboard", SystemSettings.keyboard)
                pane("Pointer Control", "cursorarrow.motionlines", SystemSettings.pointer)
            }
            Section("Current values") {
                LabeledContent("Key repeat interval", value: ms("KeyRepeat"))
                LabeledContent("Delay until repeat", value: ms("InitialKeyRepeat"))
                LabeledContent("Mouse tracking speed", value: number("com.apple.mouse.scaling"))
                LabeledContent("Trackpad tracking speed", value: number("com.apple.trackpad.scaling"))
                LabeledContent("Natural scrolling", value: natural)
            }
            Section {
                Toggle("Play sounds for lessons and tests", isOn: $model.prefs.lessonSounds)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Input Settings")
    }

    private func pane(_ title: String, _ symbol: String, _ id: String) -> some View {
        LabeledContent {
            Button("Open") { SystemSettings.open(id) }
        } label: {
            Label(title, systemImage: symbol)
        }
    }
}
