import Foundation
import FluentCore

@MainActor
final class Store: ObservableObject {
    @Published private(set) var results: [TestResult] = []
    @Published private(set) var keys: KeyStats = [:]
    @Published private(set) var bests: [String: Double] = [:]
    private let url: URL?

    private struct Payload: Codable {
        var results: [TestResult]
        var keys: KeyStats
        var bests: [String: Double]?
    }

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Fluent", isDirectory: true)
        let old = base.appendingPathComponent("Cadence", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path), FileManager.default.fileExists(atPath: old.path) {
            try? FileManager.default.moveItem(at: old, to: dir)
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("history.json")
        load()
    }

    var weakKeys: [Character] { WeakKeys.rank(keys) }

    func best(for config: TestConfig) -> TestResult? {
        results.filter { $0.config.key == config.key }.max { $0.wpm < $1.wpm }
    }

    func add(_ r: TestResult, keys session: KeyStats) {
        results.append(r)
        if results.count > 2000 { results.removeFirst(results.count - 2000) }
        for (k, v) in session {
            var s = keys[k] ?? KeyStat()
            s.merge(v)
            keys[k] = s
        }
        save()
    }

    /// True if better
    @discardableResult
    func setBest(_ key: String, _ value: Double, lowerIsBetter: Bool = false) -> Bool {
        if let old = bests[key], lowerIsBetter ? value >= old : value <= old { return false }
        let first = bests[key] == nil
        bests[key] = value
        save()
        return !first
    }

    func removeBests(prefix: String) {
        bests = bests.filter { !$0.key.hasPrefix(prefix) }
        save()
    }

    func reset() {
        results = []
        keys = [:]
        bests = [:]
        save()
    }

    var streak: Int {
        let cal = Calendar.current
        let days = Set(results.map { cal.startOfDay(for: $0.date) })
        var day = cal.startOfDay(for: Date())
        if !days.contains(day) { day = cal.date(byAdding: .day, value: -1, to: day)! }
        var n = 0
        while days.contains(day) {
            n += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return n
    }

    func csv() -> String {
        let f = ISO8601DateFormatter()
        var out = "date,test,wpm,raw,accuracy,consistency,errors,seconds\n"
        for r in results {
            out += "\(f.string(from: r.date)),\(r.config.mode.rawValue) \(r.config.label),"
            out += String(format: "%.1f,%.1f,%.1f,%.1f,%d,%.1f\n", r.wpm, r.raw, r.accuracy, r.consistency, r.errors, r.duration)
        }
        return out
    }

    private func load() {
        guard let url, let data = try? Data(contentsOf: url) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        if let p = try? dec.decode(Payload.self, from: data) {
            results = p.results
            keys = p.keys
            bests = p.bests ?? [:]
        }
    }

    private func save() {
        guard let url else { return }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(Payload(results: results, keys: keys, bests: bests)) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
