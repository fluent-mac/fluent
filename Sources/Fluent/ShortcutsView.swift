import SwiftUI
import AppKit
import FluentCore

/// Sees keys first
@MainActor
final class ComboMonitor: ObservableObject {
    var target: KeyCombo?
    var onMatch: (() -> Void)?
    private var token: Any?

    func start() {
        guard token == nil else { return }
        token = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            let code = e.keyCode
            let flags = e.modifierFlags
            let hit = MainActor.assumeIsolated { self?.process(code, flags) ?? false }
            return hit ? nil : e
        }
    }

    func stop() {
        if let t = token { NSEvent.removeMonitor(t) }
        token = nil
    }

    private func process(_ code: UInt16, _ f: NSEvent.ModifierFlags) -> Bool {
        guard let t = target,
              let c = KeyCombo(keyCode: code, control: f.contains(.control), option: f.contains(.option), shift: f.contains(.shift), command: f.contains(.command)),
              c == t else { return false }
        onMatch?()
        return true
    }
}

struct ShortcutsView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case learn = "Learn"
        case all = "All"
        var id: String { rawValue }
    }

    @State private var mode = Mode.learn

    var body: some View {
        Group {
            switch mode {
            case .learn: ShortcutLearnView()
            case .all: ShortcutList()
            }
        }
        .navigationTitle("Shortcuts")
        .toolbar {
            ToolbarItem {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

struct ShortcutLearnView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var combos = ComboMonitor()
    @State private var index = 0
    @State private var passed = false
    @State private var started = false

    private let all = MacShortcuts.all

    private func isDone(_ s: MacShortcut) -> Bool { store.bests["shortcut.\(s.id)"] != nil }
    private var doneCount: Int { all.filter(isDone).count }
    private var finished: Bool { doneCount == all.count && !passed }
    private var current: MacShortcut { all[index] }

    var body: some View {
        ZStack {
            if finished {
                complete
            } else {
                card
                    .id(current.id)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .animation(.smooth(duration: 0.4), value: index)
        .animation(.smooth(duration: 0.4), value: finished)
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationSubtitle("\(doneCount) of \(all.count) done")
        .toolbar {
            ToolbarItem {
                Button { move(-1) } label: { Label("Previous", systemImage: "chevron.left") }
                    .disabled(index == 0 || finished)
            }
            ToolbarItem {
                Button { move(1) } label: { Label("Next", systemImage: "chevron.right") }
                    .disabled(index == all.count - 1 || finished)
            }
            ToolbarItem {
                Menu {
                    ForEach(MacShortcuts.categories, id: \.self) { c in
                        Button(c) { jump(c) }
                    }
                } label: {
                    Label("Categories", systemImage: "list.bullet")
                }
            }
            ToolbarItem {
                Button("Reset") {
                    store.removeBests(prefix: "shortcut.")
                    index = 0
                    passed = false
                    retarget()
                }
                .disabled(doneCount == 0)
            }
        }
        .onAppear {
            combos.onMatch = { pass() }
            if !started {
                started = true
                index = all.firstIndex { !isDone($0) } ?? 0
            }
            retarget()
            combos.start()
        }
        .onDisappear { combos.stop() }
        .onChange(of: index) { retarget() }
        .onChange(of: finished) { retarget() }
    }

    private var card: some View {
        VStack(spacing: 26) {
            ProgressView(value: Double(doneCount), total: Double(all.count))
                .frame(width: 220)
                .accessibilityHidden(true)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.primary.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
                .frame(maxWidth: 520, minHeight: 200, maxHeight: 220)
                .overlay {
                    if passed { SuccessMark() } else { ShortcutIllustration(keys: current.keys).padding() }
                }
            VStack(spacing: 8) {
                Text(current.action).font(.largeTitle.weight(.semibold))
                Text(current.category).font(.title3).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            if !current.detectable {
                Button("Done") { pass() }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(current.action), \(current.keys)")
    }

    private var complete: some View {
        VStack(spacing: 22) {
            SuccessMark()
            Text("All \(all.count) shortcuts done").font(.largeTitle.weight(.semibold))
            Button("Practice Again") {
                store.removeBests(prefix: "shortcut.")
                index = 0
            }
            .buttonStyle(.glassProminent)
        }
    }

    private func retarget() {
        combos.target = finished || !current.detectable ? nil : current.combo
    }

    private func move(_ d: Int) {
        passed = false
        index = min(all.count - 1, max(0, index + d))
    }

    private func jump(_ category: String) {
        passed = false
        if let i = all.firstIndex(where: { $0.category == category }) { index = i }
    }

    private func pass() {
        guard !passed else { return }
        store.setBest("shortcut.\(current.id)", 1)
        passed = true
        if model.prefs.lessonSounds { Feedback.success() }
        let id = current.id
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard current.id == id else { return }
            let after = (all[(index + 1)...] + all[..<index]).first { !isDone($0) }
            passed = false
            if let n = after, let i = all.firstIndex(where: { $0.id == n.id }) { index = i }
        }
    }
}

struct ShortcutList: View {
    @State private var query = ""

    private var matches: [MacShortcut] { MacShortcuts.search(query) }

    var body: some View {
        List {
            ForEach(MacShortcuts.categories, id: \.self) { cat in
                let rows = matches.filter { $0.category == cat }
                if !rows.isEmpty {
                    Section(cat) {
                        ForEach(rows) { s in
                            HStack(spacing: 16) {
                                Text(s.action)
                                Spacer(minLength: 16)
                                Text(s.keys)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                    .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
        .overlay {
            if matches.isEmpty { ContentUnavailableView.search(text: query) }
        }
        .searchable(text: $query, prompt: "Search shortcuts")
    }
}
