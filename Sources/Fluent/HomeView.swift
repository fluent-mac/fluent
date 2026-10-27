import SwiftUI
import FluentCore

struct HomeView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store

    private var today: Int {
        store.results.filter { Calendar.current.isDateInToday($0.date) }.count
    }
    private var bestWpm: Double? { store.results.map(\.wpm).max() }
    private var nextLesson: Lesson? { Lesson.all.first { store.bests["lesson.\($0.id)"] == nil } }
    private var nextShortcut: MacShortcut? { MacShortcuts.all.first { store.bests["shortcut.\($0.id)"] == nil } }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                    .resizable()
                    .frame(width: 112, height: 112)
                    .accessibilityHidden(true)
                VStack(spacing: 6) {
                    Text(store.results.isEmpty ? "Welcome to Fluent" : "Welcome back")
                        .font(.system(size: 34, weight: .bold))
                    Text("Pick something to start.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                if !store.results.isEmpty { stats }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                    HomeCard(symbol: "text.cursor", title: "Typing test", detail: "\(model.prefs.mode.title), \(model.activeConfig.label)") {
                        model.newTest()
                    }
                    if !store.weakKeys.isEmpty {
                        HomeCard(symbol: "scope", title: "Practice weak keys",
                                 detail: store.weakKeys.prefix(5).map(String.init).joined(separator: " ")) {
                            model.startDrill()
                        }
                    }
                    HomeCard(symbol: "cursorarrow.click.2", title: "Click speed", detail: "How fast can you click?") {
                        model.section = .clicks
                    }
                    HomeCard(symbol: "target", title: "Aim", detail: "Test your aim") {
                        model.section = .aim
                    }
                    if let l = nextLesson {
                        HomeCard(symbol: "hand.draw", title: "Next gesture", detail: l.title) { model.section = .trackpad }
                    }
                    if let s = nextShortcut {
                        HomeCard(symbol: "command", title: "Next shortcut", detail: "\(s.action), \(s.keys)") { model.section = .shortcuts }
                    }
                    HomeCard(symbol: "checklist", title: "Mac Check", detail: "Read this Mac's hardware") {
                        model.section = .macCheck
                    }
                }
            }
            .padding(36)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Home")
    }

    private var stats: some View {
        HStack(spacing: 14) {
            tile(store.streak == 1 ? "1 day" : "\(store.streak) days", "Streak")
            tile(bestWpm.map { String(format: "%.0f wpm", $0) } ?? "None", "Best")
            tile(today >= model.prefs.dailyGoal ? "Done" : "\(today) of \(model.prefs.dailyGoal)", "Daily goal")
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.weight(.semibold)).monospacedDigit()
            Text(label).font(.callout).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct HomeCard: View {
    let symbol: String
    let title: String
    let detail: String
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol).font(.title2).foregroundStyle(Color.accentColor)
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary).lineLimit(2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(16)
            .background(hover ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .accessibilityElement(children: .combine)
    }
}
