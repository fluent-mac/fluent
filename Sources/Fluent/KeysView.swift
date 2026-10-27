import SwiftUI
import FluentCore

struct KeysView: View {
    enum Metric: String, CaseIterable, Identifiable {
        case speed = "Speed"
        case accuracy = "Accuracy"
        var id: String { rawValue }
    }

    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @State private var metric: Metric = .speed
    @State private var selected: Character?

    private var letters: [(Character, KeyStat)] {
        store.keys.compactMap { k, v in
            guard k.count == 1, let c = k.first, c != " ", v.attempts > 0 else { return nil }
            return (c, v)
        }
    }

    var body: some View {
        Group {
            if letters.isEmpty {
                ContentUnavailableView {
                    Label("No Key Data Yet", systemImage: "keyboard")
                } description: {
                    Text("Finish a few tests and Fluent shows which keys are slow or missed.")
                } actions: {
                    Button("Start Typing") { model.section = .practice }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                content
            }
        }
        .navigationTitle("Keys")
        .toolbar {
            ToolbarItem {
                Picker("Show", selection: $metric) {
                    ForEach(Metric.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            if !store.weakKeys.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Practice Weak Keys") { model.startDrill() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                KeyboardView(
                    layout: model.prefs.layout,
                    intensity: intensity,
                    selection: selected,
                    onSelect: { selected = ($0 == selected) ? nil : $0 },
                    keySize: 46
                )
                legend
                detail
                HStack(alignment: .top, spacing: 64) {
                    ranked("Slowest Keys", items: slowest) { "\(Int($0.latency ?? 0)) ms" }
                    ranked("Most Missed Keys", items: missed) { String(format: "%.1f%%", $0.errorRate * 100) }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var slowest: [(Character, KeyStat)] {
        letters.filter { $0.1.latency != nil && $0.1.attempts >= 10 }
            .sorted { ($0.1.latency ?? 0) > ($1.1.latency ?? 0) }
            .prefix(5).map { $0 }
    }

    private var missed: [(Character, KeyStat)] {
        letters.filter { $0.1.attempts >= 10 }
            .sorted { $0.1.errorRate > $1.1.errorRate }
            .prefix(5).map { $0 }
    }

    private func intensity(_ ch: Character) -> Double {
        guard let s = store.keys[String(ch)], s.attempts > 0 else { return 0 }
        switch metric {
        case .speed:
            let lats = letters.compactMap(\.1.latency)
            guard let lo = lats.min(), let hi = lats.max(), hi > lo, let l = s.latency else { return 0 }
            return (l - lo) / (hi - lo)
        case .accuracy:
            let hi = letters.map { $0.1.errorRate }.max() ?? 0
            return hi > 0 ? s.errorRate / hi : 0
        }
    }

    private var legend: some View {
        HStack(spacing: 10) {
            Text(metric == .speed ? "Faster" : "Fewer misses")
            LinearGradient(colors: [Color.accentColor.opacity(0.05), Color.accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                .frame(width: 120, height: 8)
                .clipShape(Capsule())
            Text(metric == .speed ? "Slower" : "More misses")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var detail: some View {
        if let c = selected, let s = store.keys[String(c)] {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(c).uppercased()).font(.title2.weight(.semibold))
                Text("\(s.attempts) presses, \(String(format: "%.1f", s.errorRate * 100))% missed, \(Int(s.latency ?? 0)) ms on average.")
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Select a key for its numbers.")
                .foregroundStyle(.secondary)
        }
    }

    private func ranked(_ title: String, items: [(Character, KeyStat)], value: @escaping (KeyStat) -> String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            ForEach(items, id: \.0) { c, s in
                HStack(spacing: 14) {
                    Text(String(c).uppercased())
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 30, height: 30)
                        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(value(s)).monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
