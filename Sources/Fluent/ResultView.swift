import SwiftUI
import Charts
import FluentCore

struct ResultView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    let result: TestResult

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(Int(result.wpm.rounded()))")
                    .font(.system(size: 72, weight: .semibold))
                    .monospacedDigit()
                Text("words per minute")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if model.isNewBest, let prev = model.previousBest {
                    Label("Personal best, up \(Int((result.wpm - prev.wpm).rounded())) from \(Int(prev.wpm.rounded()))", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 6)
                } else if let prev = model.previousBest {
                    Text("Your best for this test is \(Int(prev.wpm.rounded())) wpm.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                }
            }

            HStack(spacing: 36) {
                metric("Accuracy", "\(Int(result.accuracy.rounded()))%")
                metric("Raw", "\(Int(result.raw.rounded()))")
                metric("Consistency", "\(Int(result.consistency.rounded()))%")
                metric("Errors", "\(result.errors)")
                metric("Time", clockString(result.duration))
            }

            chart
                .frame(height: 150)

            HStack(spacing: 12) {
                Button("Next Test") { model.newTest() }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                Button("Repeat Test") { model.repeatTest() }
                    .buttonStyle(.glass)
                if !store.weakKeys.isEmpty {
                    Button("Practice Weak Keys") { model.startDrill() }
                        .buttonStyle(.glass)
                }
            }
            .controlSize(.large)
        }
        .frame(maxWidth: 820)
        .padding(.horizontal, 48)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var chart: some View {
        let smooth = Smoothing.movingAverage(result.rates.map(Double.init), window: 3)
        if smooth.count > 1 {
            Chart {
                ForEach(Array(smooth.enumerated()), id: \.offset) { i, v in
                    LineMark(x: .value("Second", i + 1), y: .value("Words per minute", v))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)
                }
                ForEach(result.errorSeconds, id: \.self) { s in
                    if s < smooth.count {
                        PointMark(x: .value("Second", s + 1), y: .value("Words per minute", smooth[s]))
                            .symbol(.cross)
                            .symbolSize(70)
                            .foregroundStyle(Color(nsColor: .systemRed))
                    }
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxisLabel("Seconds")
            .chartYAxisLabel("wpm")
            .accessibilityLabel("Speed over time. Crosses mark seconds with errors.")
        }
    }
}
