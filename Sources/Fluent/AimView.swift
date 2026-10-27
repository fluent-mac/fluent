import SwiftUI
import FluentCore

struct AimView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var model: AppModel
    @State private var phase = Phase.idle
    @State private var hits = 0
    @State private var misses = 0
    @State private var times: [Double] = []
    @State private var spot = CGPoint(x: 0.5, y: 0.5)
    @State private var spawned = 0.0
    @State private var left = 30.0
    @State private var newBest = false
    @State private var ticker: Task<Void, Never>?

    private let size = 64.0
    private enum Phase { case idle, running, done }

    private var bestKey: String { "aim.hits.\(model.prefs.aimSeconds)" }
    private var accuracy: Double { hits + misses == 0 ? 0 : Double(hits) / Double(hits + misses) * 100 }
    private var average: Double { times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count) * 1000 }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 44) {
                stat("\(hits)", "Hits")
                stat(String(format: "%.1f", phase == .idle ? Double(model.prefs.aimSeconds) : left), "Seconds left")
                stat(String(format: "%.0f%%", accuracy), "Accuracy")
                stat(store.bests[bestKey].map { String(format: "%.0f", $0) } ?? "None", "Best")
            }
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(.quaternary.opacity(0.4))
                    switch phase {
                    case .idle:
                        prompt("Click the targets as they appear.", "Start")
                    case .done:
                        prompt(summary, "Try Again")
                    case .running:
                        Button { hit() } label: {
                            Circle().fill(Color.accentColor).frame(width: size, height: size)
                                .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 6).padding(14))
                        }
                        .buttonStyle(.plain)
                        .position(x: spot.x * (geo.size.width - size) + size / 2,
                                  y: spot.y * (geo.size.height - size) + size / 2)
                        .accessibilityLabel("Target")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { if phase == .running { misses += 1 } }
            }
            if phase != .running {
                GlassSlider(title: "Time", unit: "s", value: $model.prefs.aimSeconds, range: 5...120, step: 5)
            }
        }
        .padding(24)
        .navigationTitle("Aim")
        .onDisappear { ticker?.cancel() }
    }

    private var summary: String {
        var s = String(format: "%d hits, %.0f ms on average, %.0f%% accuracy.", hits, average, accuracy)
        if newBest { s += " New best." }
        return s
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title.weight(.semibold)).monospacedDigit()
            Text(label).font(.callout).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func prompt(_ text: String, _ button: String) -> some View {
        VStack(spacing: 14) {
            Text(text).font(.title3).multilineTextAlignment(.center)
            Button(button) { start() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    private func spawn() {
        spot = CGPoint(x: .random(in: 0...1), y: .random(in: 0...1))
        spawned = AppModel.now
    }

    private func hit() {
        hits += 1
        times.append(AppModel.now - spawned)
        spawn()
    }

    private func start() {
        hits = 0
        misses = 0
        times = []
        left = Double(model.prefs.aimSeconds)
        newBest = false
        phase = .running
        spawn()
        ticker?.cancel()
        ticker = Task { @MainActor in
            while left > 0, phase == .running {
                try? await Task.sleep(for: .milliseconds(100))
                if Task.isCancelled { return }
                left = max(0, left - 0.1)
            }
            if phase == .running { finish() }
        }
    }

    private func finish() {
        phase = .done
        newBest = store.setBest(bestKey, Double(hits))
    }
}
