import SwiftUI
import Combine
import AppKit
import FluentCore

enum AppSection: String, CaseIterable, Identifiable {
    case home, practice, progress, keys, clicks, reaction, aim, mouse, keyboard, trackpad, shortcuts, macCheck, surface, display, audio, camera, tweaks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .practice: return "Practice"
        case .progress: return "Progress"
        case .keys: return "Keys"
        case .clicks: return "Click Speed"
        case .reaction: return "Reaction"
        case .aim: return "Aim"
        case .mouse: return "Mouse"
        case .keyboard: return "Keyboard"
        case .trackpad: return "Trackpad"
        case .shortcuts: return "Shortcuts"
        case .macCheck: return "Mac Check"
        case .surface: return "Trackpad Surface"
        case .display: return "Display Test"
        case .audio: return "Audio"
        case .camera: return "Camera"
        case .tweaks: return "Input Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .practice: return "text.cursor"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .keys: return "square.grid.3x3.fill"
        case .clicks: return "cursorarrow.click.2"
        case .reaction: return "bolt.fill"
        case .aim: return "target"
        case .mouse: return "computermouse"
        case .keyboard: return "keyboard"
        case .trackpad: return "hand.draw"
        case .shortcuts: return "command"
        case .macCheck: return "checklist"
        case .surface: return "rectangle.split.3x3"
        case .display: return "display"
        case .audio: return "speaker.wave.2"
        case .camera: return "camera"
        case .tweaks: return "switch.2"
        }
    }

    static let groups: [(title: String, items: [AppSection])] = [
        ("Type", [.practice, .progress, .keys]),
        ("Test", [.clicks, .reaction, .aim, .mouse, .keyboard]),
        ("Learn", [.trackpad, .shortcuts]),
        ("Hardware", [.macCheck, .surface, .display, .audio, .camera]),
        ("System", [.tweaks]),
    ]
}

struct Token: Identifiable, Equatable {
    let id: Int
    let range: Range<Int>
    let text: String
}

struct Prefs: Codable, Equatable {
    var mode: TestMode = .time
    var timeLimit = 30
    var wordCount = 25
    var punctuation = false
    var numbers = false
    var strict = false
    var textSize = 24.0
    var layout: KeyboardLayout = .qwerty
    var showKeyboard = false
    var sound = false
    var raceBest = true
    var customText = ""
    var lessonSounds = true
    var clickDuration = 5
    var clickKeyboard = false
    var floating = false
    var dailyGoal = 3
    var aimSeconds = 30
}

@MainActor
final class AppModel: ObservableObject {
    @Published var prefs: Prefs { didSet { prefsChanged(from: oldValue) } }
    @Published var section: AppSection = .practice
    @Published private(set) var session = TypingSession(text: "")
    @Published private(set) var tokens: [Token] = []
    @Published private(set) var activeConfig = TestConfig(mode: .time, amount: 30, punctuation: false, numbers: false)
    @Published private(set) var result: TestResult?
    @Published private(set) var isNewBest = false
    @Published private(set) var previousBest: TestResult?
    @Published private(set) var clock = 0.0
    @Published private(set) var testID = UUID()
    @Published private(set) var ghostWpm: Double?
    @Published var showCustomSheet = false
    @Published var settingsRequest = 0
    @Published var helpRequest = 0
    @Published var showWelcome = false

    let store: Store
    var frozen = false
    private var ticker: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    static var now: Double { ProcessInfo.processInfo.systemUptime }

    init(store: Store) {
        self.store = store
        self.prefs = Self.loadPrefs() ?? Prefs()
        store.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &bag)
        newTest()
        section = .home
        showWelcome = !UserDefaults.standard.bool(forKey: "welcomed")
    }

    // MARK: Tests

    func newTest() {
        section = .practice
        if prefs.mode == .custom, TextGenerator.normalize(prefs.customText).isEmpty {
            showCustomSheet = true
            start(text: generate(for: .words), mode: .words)
            return
        }
        start(text: generate(for: prefs.mode), mode: prefs.mode)
    }

    func repeatTest() {
        guard !session.target.isEmpty else { return }
        section = .practice
        start(text: String(session.target), mode: activeConfig.mode)
    }

    func startDrill() {
        let weak = store.weakKeys
        guard !weak.isEmpty else { return }
        var g = SystemRandomNumberGenerator()
        section = .practice
        start(text: TextGenerator.drill(weak: weak, count: 40, using: &g), mode: .drill)
    }

    func start(text: String, mode: TestMode) {
        ticker?.cancel()
        frozen = false
        let words = mode.usesWordList
        let amount = mode == .time ? prefs.timeLimit : (mode == .words ? prefs.wordCount : 0)
        activeConfig = TestConfig(mode: mode, amount: amount, punctuation: words && prefs.punctuation, numbers: words && prefs.numbers)
        session = TypingSession(text: text, strict: prefs.strict, timeLimit: mode == .time ? Double(prefs.timeLimit) : nil)
        tokens = Self.tokenize(session.target)
        ghostWpm = mode == .custom ? nil : store.best(for: activeConfig)?.wpm
        result = nil
        isNewBest = false
        previousBest = nil
        clock = Self.now
        testID = UUID()
    }

    private func generate(for mode: TestMode) -> String {
        var g = SystemRandomNumberGenerator()
        let opts = TextOptions(punctuation: prefs.punctuation, numbers: prefs.numbers)
        switch mode {
        case .time: return TextGenerator.words(count: 500, options: opts, using: &g)
        case .words: return TextGenerator.words(count: prefs.wordCount, options: opts, using: &g)
        case .sentences: return TextGenerator.sentences(count: 3, using: &g)
        case .custom: return String(TextGenerator.normalize(prefs.customText).prefix(5000))
        case .drill: return TextGenerator.words(count: 25, options: TextOptions(), using: &g)
        }
    }

    static func tokenize(_ t: [Character]) -> [Token] {
        var out: [Token] = []
        var start = 0
        for (i, c) in t.enumerated() where c == " " {
            out.append(Token(id: out.count, range: start..<(i + 1), text: String(t[start...i])))
            start = i + 1
        }
        if start < t.count {
            out.append(Token(id: out.count, range: start..<t.count, text: String(t[start...])))
        }
        return out
    }

    // MARK: Input

    func handle(_ press: KeyPress) -> KeyPress.Result {
        if result != nil { return .ignored }
        let m = press.modifiers
        if m.contains(.command) || m.contains(.control) { return .ignored }
        switch press.key {
        case .delete:
            if m.contains(.option) { session.deleteWord() } else { session.backspace() }
            return .handled
        case .escape:
            newTest()
            return .handled
        case .tab, .return, .upArrow, .downArrow, .leftArrow, .rightArrow:
            return .ignored
        default:
            break
        }
        if m.contains(.option) { return .ignored }
        var handled = false
        for ch in press.characters where Self.typable(ch) {
            type(ch)
            handled = true
        }
        return handled ? .handled : .ignored
    }

    static func typable(_ c: Character) -> Bool {
        c == " " || c.isLetter || c.isNumber || c.isPunctuation || c.isSymbol
    }

    func type(_ ch: Character) {
        let wasStarted = session.isStarted
        let before = session.cursor
        session.type(ch, now: Self.now)
        if !wasStarted && session.isStarted {
            clock = Self.now
            startTicker()
        }
        if prefs.sound {
            NSSound(named: session.cursor > before ? "Tink" : "Funk")?.play()
        }
        if session.isFinished { finish() }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard !frozen else { return }
        let n = Self.now
        clock = n
        session.tick(now: n)
        if session.isFinished && result == nil { finish() }
    }

    private func finish() {
        ticker?.cancel()
        guard let r = session.makeResult(config: activeConfig) else { return }
        let keep = session.strokes.count >= 5
        previousBest = store.best(for: activeConfig)
        if let p = previousBest, r.wpm > p.wpm, activeConfig.mode != .custom { isNewBest = true }
        if keep { store.add(r, keys: session.keys) }
        result = r
        AccessibilityNotification.Announcement(
            "Test finished. \(Int(r.wpm.rounded())) words per minute, \(Int(r.accuracy.rounded())) percent accuracy."
        ).post()
    }

    var ghostIndex: Int? {
        guard prefs.raceBest, let g = ghostWpm, session.isStarted, !session.isFinished, let s = session.startedAt else { return nil }
        return Int(g * 5 / 60 * max(0, clock - s))
    }

    var activeToken: Int {
        let c = session.cursor
        return tokens.firstIndex { c < $0.range.upperBound } ?? max(0, tokens.count - 1)
    }

    // MARK: Menu actions

    func setMode(_ m: TestMode) {
        section = .practice
        prefs.mode = m
    }

    func setTime(_ n: Int) {
        section = .practice
        prefs.mode = .time
        prefs.timeLimit = n
    }

    func setWords(_ n: Int) {
        section = .practice
        prefs.mode = .words
        prefs.wordCount = n
    }

    func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Fluent History.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            try? store.csv().write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func applyFloating() {
        for w in NSApplication.shared.windows where w.canBecomeMain {
            w.level = prefs.floating ? .floating : .normal
        }
    }

    // MARK: Prefs

    private func prefsChanged(from old: Prefs) {
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: "prefs")
        }
        let restart = old.mode != prefs.mode
            || old.timeLimit != prefs.timeLimit
            || old.wordCount != prefs.wordCount
            || old.punctuation != prefs.punctuation
            || old.numbers != prefs.numbers
            || old.strict != prefs.strict
            || (prefs.mode == .custom && old.customText != prefs.customText)
        if old.floating != prefs.floating { applyFloating() }
        if restart { newTest() }
    }

    private static func loadPrefs() -> Prefs? {
        guard let data = UserDefaults.standard.data(forKey: "prefs") else { return nil }
        return try? JSONDecoder().decode(Prefs.self, from: data)
    }
}
