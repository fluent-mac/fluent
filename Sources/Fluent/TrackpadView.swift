import SwiftUI
import FluentCore

struct TrackpadView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var monitor = GestureMonitor()
    @State private var index = 0
    @State private var passed = false
    @State private var started = false

    private let lessons = Lesson.all

    private var groups: [String] {
        var seen: [String] = []
        for l in lessons where !seen.contains(l.group) { seen.append(l.group) }
        return seen
    }

    private func isDone(_ l: Lesson) -> Bool { store.bests["lesson.\(l.id)"] != nil }
    private var doneCount: Int { lessons.filter(isDone).count }
    private var finished: Bool { doneCount == lessons.count && !passed }
    private var lesson: Lesson { lessons[index] }

    var body: some View {
        ZStack {
            if finished {
                complete
            } else {
                card
                    .id(lesson.id)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .animation(.smooth(duration: 0.4), value: index)
        .animation(.smooth(duration: 0.4), value: finished)
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Trackpad")
        .navigationSubtitle("\(doneCount) of \(lessons.count) done")
        .toolbar {
            ToolbarItem {
                Button { move(-1) } label: { Label("Previous", systemImage: "chevron.left") }
                    .disabled(index == 0 || finished)
            }
            ToolbarItem {
                Button { move(1) } label: { Label("Next", systemImage: "chevron.right") }
                    .disabled(index == lessons.count - 1 || finished)
            }
            ToolbarItem {
                Menu {
                    ForEach(groups, id: \.self) { g in
                        Section(g) {
                            ForEach(lessons.filter { $0.group == g }) { l in
                                Button { jump(l) } label: {
                                    if isDone(l) { Label(l.title, systemImage: "checkmark") } else { Text(l.title) }
                                }
                            }
                        }
                    }
                } label: {
                    Label("Lessons", systemImage: "list.bullet")
                }
            }
            ToolbarItem {
                Button("Reset") {
                    store.removeBests(prefix: "lesson.")
                    index = 0
                    passed = false
                }
                .disabled(doneCount == 0)
            }
        }
        .onAppear {
            monitor.onInput = handle
            if !started {
                started = true
                index = lessons.firstIndex { !isDone($0) } ?? 0
            }
        }
        .onDisappear { monitor.onInput = nil }
    }

    private var card: some View {
        VStack(spacing: 26) {
            ProgressView(value: Double(doneCount), total: Double(lessons.count))
                .frame(width: 220)
                .accessibilityHidden(true)
            pad
            VStack(spacing: 8) {
                Text(lesson.title).font(.largeTitle.weight(.semibold))
                Text(lesson.hint).font(.title3)
                Text(lesson.effect).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            Button("Open Settings") { SystemSettings.open(lesson.pane) }
                .buttonStyle(.glass)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pad: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.primary.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
            .aspectRatio(1.5, contentMode: .fit)
            .frame(maxWidth: 480)
            .overlay {
                if passed { SuccessMark() } else { GestureIllustration(demo: lesson.demo) }
            }
            .overlay {
                GeometryReader { geo in
                    ForEach(monitor.touches, id: \.id) { t in
                        Circle()
                            .fill(.white.opacity(0.9))
                            .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 3))
                            .frame(width: 34, height: 34)
                            .position(x: t.x * geo.size.width, y: (1 - t.y) * geo.size.height)
                    }
                }
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                Text("\(min(doneCount + (passed ? 0 : 1), lessons.count)) of \(lessons.count)")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .glassEffect(.regular, in: .capsule)
                    .padding(14)
                    .allowsHitTesting(false)
            }
            .overlay(EventCapture(handlers: monitor.handlers))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Trackpad practice area. \(lesson.hint)")
    }

    private var complete: some View {
        VStack(spacing: 22) {
            SuccessMark()
            Text("All \(lessons.count) lessons done").font(.largeTitle.weight(.semibold))
            Button("Practice Again") {
                store.removeBests(prefix: "lesson.")
                index = 0
            }
            .buttonStyle(.glassProminent)
        }
    }

    private func move(_ d: Int) {
        passed = false
        monitor.clear()
        index = min(lessons.count - 1, max(0, index + d))
    }

    private func jump(_ l: Lesson) {
        passed = false
        monitor.clear()
        if let i = lessons.firstIndex(where: { $0.id == l.id }) { index = i }
    }

    private func handle(_ g: GestureInput) {
        guard !passed, lesson.accepts(g) else { return }
        store.setBest("lesson.\(lesson.id)", 1)
        passed = true
        if model.prefs.lessonSounds { Feedback.success() }
        let id = lesson.id
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            guard lesson.id == id else { return }
            monitor.clear()
            let after = (lessons[(index + 1)...] + lessons[..<index]).first { !isDone($0) }
            passed = false
            if let n = after, let i = lessons.firstIndex(where: { $0.id == n.id }) { index = i }
        }
    }
}
