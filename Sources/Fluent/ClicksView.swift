import SwiftUI
import AppKit
import FluentCore

struct ClicksView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @State private var run = ClickRun(duration: 5)
    @State private var now = AppModel.now
    @State private var done = false
    @State private var isBest = false
    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var seconds: Int { model.prefs.clickDuration }
    private var keyboard: Bool { model.prefs.clickKeyboard }
    private var bestKey: String { "clicks.\(seconds).\(keyboard ? "keys" : "mouse")" }
    private var left: Double { run.remaining(now: now) }

    private var liveRate: Double {
        if done { return run.cps }
        guard run.isStarted else { return 0 }
        return Double(run.count) / max(0.25, Double(seconds) - left)
    }

    var body: some View {
        VStack(spacing: 28) {
            HStack(alignment: .firstTextBaseline, spacing: 56) {
                stat("Per second", String(format: "%.1f", liveRate))
                stat("Clicks", "\(run.count)")
                stat("Time left", String(format: "%.1f", done ? 0 : left))
                stat("Best", store.bests[bestKey].map { String(format: "%.1f", $0) } ?? "None")
            }
            target
            if done { results }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Click Speed")
        .toolbar {
            ToolbarItem {
                Picker("Length", selection: $model.prefs.clickDuration) {
                    ForEach([1, 5, 10, 30], id: \.self) { Text("\($0) s").tag($0) }
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem {
                Picker("Input", selection: $model.prefs.clickKeyboard) {
                    Text("Mouse").tag(false)
                    Text("Keyboard").tag(true)
                }
                .pickerStyle(.segmented)
            }
        }
        .onReceive(tick) { _ in
            now = AppModel.now
            if run.isStarted && !done && left <= 0 { finish() }
        }
        .onChange(of: model.prefs.clickDuration) { reset() }
        .onChange(of: model.prefs.clickKeyboard) { reset() }
        .onDisappear { reset() }
    }

    private var target: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(done ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.06))
            .frame(maxWidth: 600, minHeight: 200, maxHeight: 260)
            .overlay {
                VStack(spacing: 6) {
                    Text(prompt).font(.title2.weight(.medium))
                    if done { Button("Try Again") { reset() }.buttonStyle(.glassProminent) }
                }
            }
            .overlay(EventCapture(handlers: handlers).allowsHitTesting(!done))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Click target")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { hit() }
    }

    private var prompt: String {
        if done { return isBest ? "New best" : "Time" }
        if run.isStarted { return keyboard ? "Keep pressing keys" : "Keep clicking" }
        return keyboard ? "Press any key to start" : "Click to start"
    }

    private var results: some View {
        let bars = run.perSecond
        let top = max(1, bars.max() ?? 1)
        return VStack(spacing: 14) {
            Text("Fastest second: \(run.peak) clicks").foregroundStyle(.secondary)
            Button("Copy Result") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(String(format: "%.1f clicks per second over %d seconds, fastest second %d", run.cps, seconds, run.peak), forType: .string)
            }
            if bars.count > 1 {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(bars.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.accentColor.opacity(0.75))
                            .frame(width: min(40, 520 / CGFloat(bars.count)), height: max(4, 90 * CGFloat(bars[i]) / CGFloat(top)))
                    }
                }
                .frame(height: 90, alignment: .bottom)
                .accessibilityHidden(true)
            }
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
        h.mouseDown = { _ in if !keyboard { hit() } }
        h.key = { e, down in
            guard down, !e.isARepeat else { return }
            if e.keyCode == 53 { reset() } else if keyboard { hit() }
        }
        return h
    }

    private func hit() {
        guard !done else { return }
        let t = AppModel.now
        now = t
        if run.click(at: t) {
            if model.prefs.sound { Feedback.tick() }
        } else {
            finish()
        }
    }

    private func finish() {
        guard !done else { return }
        done = true
        isBest = run.count > 0 && store.setBest(bestKey, run.cps)
        if model.prefs.lessonSounds { Feedback.success() }
    }

    private func reset() {
        run = ClickRun(duration: Double(seconds))
        done = false
        isBest = false
    }
}
