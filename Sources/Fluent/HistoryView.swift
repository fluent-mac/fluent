import SwiftUI
import Charts
import FluentCore

struct HistoryView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @State private var filter: TestMode?

    private var rows: [TestResult] {
        store.results.filter { filter == nil || $0.config.mode == filter }
    }

    var body: some View {
        Group {
            if store.results.isEmpty {
                ContentUnavailableView {
                    Label("No Tests Yet", systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text("Finish a test in Practice and your results show up here.")
                } actions: {
                    Button("Start Typing") { model.section = .practice }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                content
            }
        }
        .navigationTitle("Progress")
        .toolbar {
            ToolbarItem {
                Picker("Show", selection: $filter) {
                    Text("All Tests").tag(TestMode?.none)
                    ForEach(TestMode.allCases) { Text($0.title).tag(Optional($0)) }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            summary
            Chart(rows.suffix(100)) { r in
                LineMark(x: .value("Date", r.date), y: .value("Words per minute", r.wpm))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)
                PointMark(x: .value("Date", r.date), y: .value("Words per minute", r.wpm))
                    .symbolSize(22)
                    .foregroundStyle(Color.accentColor)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxisLabel("wpm")
            .frame(height: 210)
            .accessibilityLabel("Words per minute across your tests")

            Table(Array(rows.reversed())) {
                TableColumn("Date") { r in
                    Text(r.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                }
                TableColumn("Test") { r in Text(r.config.label) }
                TableColumn("WPM") { r in Text("\(Int(r.wpm.rounded()))").monospacedDigit() }
                    .width(70)
                TableColumn("Accuracy") { r in Text("\(Int(r.accuracy.rounded()))%").monospacedDigit() }
                    .width(80)
                TableColumn("Consistency") { r in Text("\(Int(r.consistency.rounded()))%").monospacedDigit() }
                    .width(90)
            }
            .frame(minHeight: 200)
        }
        .padding(24)
    }

    private var summary: some View {
        let best = rows.map(\.wpm).max() ?? 0
        let last10 = rows.suffix(10).map(\.wpm)
        let avg = last10.isEmpty ? 0 : last10.reduce(0, +) / Double(last10.count)
        let time = rows.map(\.duration).reduce(0, +)
        return HStack(alignment: .top, spacing: 48) {
            tile("Best", "\(Int(best.rounded())) wpm")
            tile("Last 10 Average", "\(Int(avg.rounded())) wpm")
            tile("Tests", "\(rows.count)")
            tile("Time Typed", durationString(time))
            tile("Day Streak", "\(store.streak)")
            Spacer()
        }
    }

    private func tile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
