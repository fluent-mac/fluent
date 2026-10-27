import Foundation

public enum TestMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case time, words, sentences, custom, drill

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .time: return "Time"
        case .words: return "Words"
        case .sentences: return "Phrases"
        case .custom: return "Custom"
        case .drill: return "Weak Keys"
        }
    }

    public var usesWordList: Bool { self == .time || self == .words }

    public static var pickable: [TestMode] { [.time, .words, .sentences, .custom] }
}

public struct TestConfig: Codable, Hashable, Sendable {
    public var mode: TestMode
    public var amount: Int
    public var punctuation: Bool
    public var numbers: Bool

    public init(mode: TestMode, amount: Int, punctuation: Bool, numbers: Bool) {
        self.mode = mode
        self.amount = amount
        self.punctuation = punctuation
        self.numbers = numbers
    }

    public var key: String {
        "\(mode.rawValue)-\(amount)-\(punctuation ? "p" : "")\(numbers ? "n" : "")"
    }

    public var label: String {
        switch mode {
        case .time: return "\(amount) s"
        case .words: return "\(amount) words"
        case .sentences: return "Phrases"
        case .custom: return "Custom text"
        case .drill: return "Weak keys"
        }
    }
}

public struct Stroke: Sendable {
    public let t: Double
    public let correct: Bool
}

public struct Metrics: Sendable {
    public var wpm: Double
    public var raw: Double
    public var accuracy: Double
    public var consistency: Double
    public var errors: Int
    public var elapsed: Double
}

/// One typing test
public struct TypingSession: Sendable {
    public let target: [Character]
    public let strict: Bool
    public let timeLimit: Double?
    public private(set) var typed: [Character] = []
    public private(set) var startedAt: Double?
    public private(set) var finalDuration: Double?
    public private(set) var strokes: [Stroke] = []
    public private(set) var keys: KeyStats = [:]
    private var lastT: Double?

    public init(text: String, strict: Bool = false, timeLimit: Double? = nil) {
        self.target = Array(text)
        self.strict = strict
        self.timeLimit = timeLimit
    }

    public var isStarted: Bool { startedAt != nil }
    public var isFinished: Bool { finalDuration != nil }
    public var cursor: Int { typed.count }

    public var totalWords: Int { target.split(separator: " ").count }
    public var completedWords: Int { min(totalWords, typed.filter { $0 == " " }.count) }

    public mutating func type(_ c: Character, now: Double) {
        guard !isFinished else { return }
        if startedAt == nil { startedAt = now }
        let t = now - startedAt!
        if let limit = timeLimit, t >= limit {
            finalDuration = limit
            return
        }
        guard typed.count < target.count else { return }
        let expected = target[typed.count]
        let ok = c == expected
        record(expected: expected, ok: ok, t: t)
        if ok || !strict { typed.append(c) }
        if typed.count == target.count { finalDuration = max(t, 0.001) }
    }

    public mutating func backspace() {
        guard !isFinished, !typed.isEmpty else { return }
        typed.removeLast()
    }

    public mutating func deleteWord() {
        guard !isFinished else { return }
        while typed.last == " " { typed.removeLast() }
        while let l = typed.last, l != " " { typed.removeLast() }
    }

    public mutating func tick(now: Double) {
        guard !isFinished, let s = startedAt, let limit = timeLimit else { return }
        if now - s >= limit { finalDuration = limit }
    }

    private mutating func record(expected: Character, ok: Bool, t: Double) {
        strokes.append(Stroke(t: t, correct: ok))
        let id = keyID(expected)
        var s = keys[id] ?? KeyStat()
        s.attempts += 1
        if !ok {
            s.errors += 1
        } else if let last = lastT {
            let dt = (t - last) * 1000
            if dt < 2000 {
                s.latencyTotal += dt
                s.latencyCount += 1
            }
        }
        keys[id] = s
        lastT = t
    }

    public func elapsed(now: Double) -> Double {
        if let d = finalDuration { return d }
        guard let s = startedAt else { return 0 }
        let e = max(0, now - s)
        if let limit = timeLimit { return min(e, limit) }
        return e
    }

    public func metrics(now: Double) -> Metrics {
        let elapsed = self.elapsed(now: now)
        let minutes = max(elapsed, 1) / 60
        var correct = 0
        for (a, b) in zip(typed, target) where a == b { correct += 1 }
        let okStrokes = strokes.filter(\.correct).count
        let accuracy = strokes.isEmpty ? 100 : 100 * Double(okStrokes) / Double(strokes.count)
        let rates = isFinished ? self.rates() : []
        return Metrics(
            wpm: Double(correct) / 5 / minutes,
            raw: Double(typed.count) / 5 / minutes,
            accuracy: accuracy,
            consistency: Self.consistency(rates),
            errors: strokes.count - okStrokes,
            elapsed: elapsed
        )
    }

    /// WPM per second
    public func rates() -> [Double] {
        guard let d = finalDuration, d > 0 else { return [] }
        var n = Int(d)
        if d - Double(n) >= 0.5 || n == 0 { n += 1 }
        var counts = [Int](repeating: 0, count: n)
        for s in strokes where s.correct { counts[min(Int(s.t), n - 1)] += 1 }
        return counts.enumerated().map { i, c in
            let len = i == n - 1 ? min(1, d - Double(i)) : 1
            return Double(c) * 12 / max(len, 0.25)
        }
    }

    static func consistency(_ r: [Double]) -> Double {
        guard r.count > 1 else { return r.isEmpty ? 0 : 100 }
        let mean = r.reduce(0, +) / Double(r.count)
        guard mean > 0 else { return 0 }
        let variance = r.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(r.count)
        return max(0, min(100, (1 - variance.squareRoot() / mean) * 100))
    }

    public func makeResult(config: TestConfig, date: Date = Date()) -> TestResult? {
        guard isFinished else { return nil }
        let m = metrics(now: 0)
        let r = rates()
        let errorSeconds = Set(strokes.filter { !$0.correct }.map { Int($0.t) })
            .filter { $0 < r.count }
            .sorted()
        return TestResult(
            id: UUID(), date: date, config: config,
            wpm: m.wpm, raw: m.raw, accuracy: m.accuracy, consistency: m.consistency,
            errors: m.errors, duration: m.elapsed,
            rates: r.map { Int($0.rounded()) }, errorSeconds: errorSeconds
        )
    }
}
