import SwiftUI
import FluentCore

struct PracticeView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let r = model.result {
                ResultView(result: r)
                    .transition(reduceMotion ? .identity : .opacity)
            } else {
                typingArea
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Practice")
        .toolbar { toolbar }
    }

    private var typingArea: some View {
        VStack(alignment: .leading, spacing: 24) {
            LiveStats()
            flow
            footer
            if !model.session.isStarted { lengthSlider }
            if model.prefs.showKeyboard {
                KeyboardView(layout: model.prefs.layout, highlight: nextKey)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: 780)
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(phases: [.down, .repeat]) { model.handle($0) }
        .onTapGesture { focused = true }
        .onAppear { focused = true }
        .onChange(of: model.testID) { focused = true }
    }

    private var flow: some View {
        let typed = model.session.typed
        let cursor = model.session.cursor
        let ghost = model.ghostIndex
        return WordFlow(activeIndex: model.activeToken) {
            ForEach(model.tokens) { tok in
                let lo = tok.range.lowerBound
                let hi = tok.range.upperBound
                TokenView(
                    target: tok.text,
                    typed: lo < typed.count ? String(typed[lo..<min(hi, typed.count)]) : "",
                    caret: (cursor >= lo && cursor < hi) ? cursor - lo : nil,
                    ghost: (ghost != nil && ghost! >= lo && ghost! < hi) ? ghost! - lo : nil,
                    size: model.prefs.textSize
                )
            }
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Typing text")
        .accessibilityValue(String(model.session.target.dropFirst(cursor)))
    }

    private var footer: some View {
        Text(model.session.isStarted ? "Press Esc for a new text." : "Start typing to begin. Press Esc for a new text.")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var lengthSlider: some View {
        if model.prefs.mode == .time {
            GlassSlider(title: "Time", unit: "s", value: $model.prefs.timeLimit, range: 5...300, step: 5)
        } else if model.prefs.mode == .words {
            GlassSlider(title: "Words", unit: "words", value: $model.prefs.wordCount, range: 5...200, step: 5)
        }
    }

    private var nextKey: Character? {
        let s = model.session
        guard s.cursor < s.target.count else { return nil }
        return Character(String(s.target[s.cursor]).lowercased())
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("Mode", selection: $model.prefs.mode) {
                ForEach(TestMode.pickable) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        if model.prefs.mode == .time {
            ToolbarItem {
                Picker("Length", selection: $model.prefs.timeLimit) {
                    ForEach(Array(Set([15, 30, 60, 120, model.prefs.timeLimit])).sorted(), id: \.self) { Text("\($0) s").tag($0) }
                }
                .pickerStyle(.menu)
            }
        }
        if model.prefs.mode == .words {
            ToolbarItem {
                Picker("Length", selection: $model.prefs.wordCount) {
                    ForEach(Array(Set([10, 25, 50, 100, model.prefs.wordCount])).sorted(), id: \.self) { Text("\($0) words").tag($0) }
                }
                .pickerStyle(.menu)
            }
        }
        if model.prefs.mode == .custom {
            ToolbarItem {
                Button("Edit Text…") { model.showCustomSheet = true }
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Toggle("Punctuation", isOn: $model.prefs.punctuation).disabled(!model.prefs.mode.usesWordList)
                Toggle("Numbers", isOn: $model.prefs.numbers).disabled(!model.prefs.mode.usesWordList)
                Divider()
                Toggle("Stop on Error", isOn: $model.prefs.strict)
                Toggle("Race Best Pace", isOn: $model.prefs.raceBest)
                Toggle("Show On-Screen Keyboard", isOn: $model.prefs.showKeyboard)
            } label: {
                Label("Options", systemImage: "slider.horizontal.3")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button { model.newTest() } label: {
                Label("New Test", systemImage: "arrow.counterclockwise")
            }
            .help("New test")
        }
    }
}

struct LiveStats: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let s = model.session
        let m = s.metrics(now: model.clock)
        HStack(alignment: .firstTextBaseline, spacing: 30) {
            stat(s.isStarted ? "\(Int(m.wpm.rounded()))" : "–", "wpm")
            stat(s.isStarted ? "\(Int(m.accuracy.rounded()))%" : "–", "accuracy")
            if let limit = s.timeLimit {
                stat(clockString(limit - m.elapsed), "left")
            } else {
                stat("\(s.completedWords)/\(s.totalWords)", "words")
            }
            Spacer()
            if model.prefs.raceBest, let g = model.ghostWpm {
                Label("Best \(Int(g.rounded())) wpm", systemImage: "trophy")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .semibold))
                .monospacedDigit()
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
