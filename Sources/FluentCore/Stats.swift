import Foundation

public struct KeyStat: Codable, Equatable, Sendable {
    public var attempts = 0
    public var errors = 0
    public var latencyTotal = 0.0
    public var latencyCount = 0

    public init() {}

    public var errorRate: Double { attempts == 0 ? 0 : Double(errors) / Double(attempts) }
    public var latency: Double? { latencyCount == 0 ? nil : latencyTotal / Double(latencyCount) }

    public mutating func merge(_ o: KeyStat) {
        attempts += o.attempts
        errors += o.errors
        latencyTotal += o.latencyTotal
        latencyCount += o.latencyCount
    }
}

public typealias KeyStats = [String: KeyStat]

public func keyID(_ c: Character) -> String { String(c).lowercased() }

public struct TestResult: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var date: Date
    public var config: TestConfig
    public var wpm: Double
    public var raw: Double
    public var accuracy: Double
    public var consistency: Double
    public var errors: Int
    public var duration: Double
    public var rates: [Int]
    public var errorSeconds: [Int]

    public init(
        id: UUID, date: Date, config: TestConfig,
        wpm: Double, raw: Double, accuracy: Double, consistency: Double,
        errors: Int, duration: Double, rates: [Int], errorSeconds: [Int]
    ) {
        self.id = id
        self.date = date
        self.config = config
        self.wpm = wpm
        self.raw = raw
        self.accuracy = accuracy
        self.consistency = consistency
        self.errors = errors
        self.duration = duration
        self.rates = rates
        self.errorSeconds = errorSeconds
    }
}

public enum Smoothing {
    public static func movingAverage(_ v: [Double], window: Int = 3) -> [Double] {
        guard window > 1, v.count > 1 else { return v }
        return v.indices.map { i in
            let lo = max(0, i - window / 2)
            let hi = min(v.count - 1, i + window / 2)
            let s = v[lo...hi]
            return s.reduce(0, +) / Double(s.count)
        }
    }
}

public enum WeakKeys {
    /// Weakest letters
    public static func rank(_ stats: KeyStats, limit: Int = 5) -> [Character] {
        let letters = stats.filter { $0.key.count == 1 && ($0.key.first?.isLetter ?? false) && $0.value.attempts >= 15 }
        guard letters.count >= 5 else { return [] }
        let lat = letters.values.compactMap(\.latency).sorted()
        let median = lat.isEmpty ? 0 : lat[lat.count / 2]
        var scored: [(Character, Double)] = []
        for (k, v) in letters {
            var slow = 0.0
            if let l = v.latency, median > 0 { slow = max(0, l / median - 1) }
            scored.append((k.first!, v.errorRate * 10 + slow))
        }
        return scored
            .filter { $0.1 > 0.15 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
}
