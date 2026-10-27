import SwiftUI
import AppKit
import FluentCore

struct MacCheckView: View {
    @EnvironmentObject var store: Store
    @StateObject private var info = MacInfo()

    private static let manual: [(id: String, title: String, symbol: String)] = [
        ("keyboard", "Every key works", "keyboard"),
        ("trackpad", "Trackpad clicks and tracks everywhere", "hand.draw"),
        ("display", "No dead pixels or marks", "display"),
        ("audio", "Speakers and microphone work", "speaker.wave.2"),
        ("camera", "Camera works", "camera"),
        ("ports", "Ports and charger work", "cable.connector"),
    ]

    private func checked(_ id: String) -> Binding<Bool> {
        Binding(
            get: { store.bests["check.\(id)"] != nil },
            set: { on in
                if on { store.setBest("check.\(id)", 1) } else { store.removeBests(prefix: "check.\(id)") }
            })
    }

    private var report: String {
        let done = Self.manual.map { "  [\(store.bests["check.\($0.id)"] != nil ? "x" : " ")] \($0.title)" }.joined(separator: "\n")
        return info.report + "\n\nChecks\n" + done
    }

    var body: some View {
        Form {
            ForEach(info.sections) { s in
                Section(s.id) {
                    ForEach(s.rows) { r in
                        LabeledContent {
                            HStack(spacing: 6) {
                                Text(r.value).textSelection(.enabled)
                                if let sym = symbol(r.level) {
                                    Image(systemName: sym.name).foregroundStyle(sym.color)
                                }
                            }
                        } label: {
                            Text(r.label)
                        }
                    }
                }
            }
            Section("Checks") {
                ForEach(Self.manual, id: \.id) { m in
                    Toggle(isOn: checked(m.id)) { Label(m.title, systemImage: m.symbol) }
                }
            }
        }
        .formStyle(.grouped)
        .overlay {
            if info.loading && info.sections.isEmpty { ProgressView() }
        }
        .navigationTitle("Mac Check")
        .toolbar {
            ToolbarItem {
                Button("Refresh") { Task { await info.load() } }
            }
            ToolbarItem {
                Button("Copy Report") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report, forType: .string)
                }
            }
        }
        .task { await info.load() }
    }

    private func symbol(_ l: Level) -> (name: String, color: Color)? {
        switch l {
        case .good: return ("checkmark.circle.fill", .green)
        case .warn: return ("exclamationmark.triangle.fill", .orange)
        case .bad: return ("xmark.octagon.fill", .red)
        case .info: return nil
        }
    }
}
