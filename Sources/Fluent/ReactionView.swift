import SwiftUI
import FluentCore

struct ReactionView: View {
    enum Phase: Equatable {
        case idle, waiting, ready, early
        case result(Double)
    }

    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @State private var phase = Phase.idle
    @State private var since = 0.0
    @State private var times: [Double] = []
    @State private var wait: Task<Void, Never>?

    private var average: Double? { times.isEmpty ? nil : times.reduce(0, +) / Double(times.count) }

    var body: some View {
        VStack(spacing: 28) {
            HStack(alignment: .firstTextBaseline, spacing: 56) {
                stat("Last", times.last.map { "\(Int($0)) ms" } ?? "None")
                stat("Average", average.map { "\(Int($0)) ms" } ?? "None")
                stat("Best", store.bests["reaction"].map { "\(Int($0)) ms" } ?? "None")
            }
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(fill)
                .frame(maxWidth: 600, minHeight: 220, maxHeight: 280)
                .overlay {
                    VStack(spacing: 6) {
                        Text(title).font(.title.weight(.semibold))
                        if let sub { Text(sub).foregroundStyle(.secondary) }
                    }
                }
                .overlay(EventCapture(handlers: handlers))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Reaction target, \(title)")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { press() }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Reaction")
        .toolbar {
            ToolbarItem { Button("Reset") { reset(); times = [] } }
        }
        .onDisappear { reset() }
    }

    private var fill: Color {
        switch phase {
        case .ready: return .green.opacity(0.6)
        case .waiting: return .red.opacity(0.35)
        case .early: return .orange.opacity(0.35)
        default: return Color.primary.opacity(0.06)
        }
    }

    private var title: String {
        switch phase {
        case .idle: return "Click to start"
        case .waiting: return "Wait for green"
        case .ready: return "Click now"
        case .early: return "Too early"
        case .result(let ms): return "\(Int(ms)) ms"
        }
    }

    private var sub: String? {
        switch phase {
        case .idle: return "Click as soon as the box turns green. Space works too."
        case .early, .result: return "Click to go again"
        default: return nil
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 40, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(title).font(.callout).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var handlers: InputHandlers {
        var h = InputHandlers()
        h.mouseDown = { _ in press() }
        h.key = { e, down in
            if down && !e.isARepeat && e.keyCode == 49 { press() }
        }
        return h
    }

    private func press() {
        switch phase {
        case .waiting:
            wait?.cancel()
            phase = .early
        case .ready:
            let ms = (AppModel.now - since) * 1000
            times = Array((times + [ms]).suffix(5))
            store.setBest("reaction", ms, lowerIsBetter: true)
            phase = .result(ms)
            if model.prefs.lessonSounds { Feedback.success() }
        default:
            phase = .waiting
            wait = Task {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 1500...4000)))
                guard !Task.isCancelled else { return }
                since = AppModel.now
                phase = .ready
            }
        }
    }

    private func reset() {
        wait?.cancel()
        phase = .idle
    }
}
