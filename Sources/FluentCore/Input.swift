import Foundation

public struct ClickRun: Sendable {
    public let duration: Double
    public private(set) var stamps: [Double] = []
    public private(set) var start: Double?

    public init(duration: Double) { self.duration = duration }

    public var isStarted: Bool { start != nil }
    public var count: Int { stamps.count }
    public var cps: Double { Double(count) / duration }

    /// False when done
    @discardableResult
    public mutating func click(at now: Double) -> Bool {
        if start == nil { start = now }
        let t = now - start!
        guard t < duration else { return false }
        stamps.append(t)
        return true
    }

    public func remaining(now: Double) -> Double {
        guard let s = start else { return duration }
        return max(0, duration - (now - s))
    }

    /// Clicks per second
    public var perSecond: [Int] {
        var out = [Int](repeating: 0, count: max(1, Int(duration.rounded(.up))))
        for t in stamps { out[min(Int(t), out.count - 1)] += 1 }
        return out
    }

    /// Peak clicks
    public var peak: Int {
        var best = 0
        var lo = 0
        for hi in stamps.indices {
            while stamps[hi] - stamps[lo] >= 1 { lo += 1 }
            best = max(best, hi - lo + 1)
        }
        return best
    }
}

public struct PollingEstimator: Sendable {
    private var last: Double?
    public private(set) var intervals: [Double] = []

    public init() {}

    public mutating func add(_ t: Double) {
        if let l = last {
            let d = t - l
            if d > 0 && d < 0.05 {
                intervals.append(d)
                if intervals.count > 800 { intervals.removeFirst(intervals.count - 800) }
            }
        }
        last = t
    }

    public mutating func reset() {
        last = nil
        intervals = []
    }

    public var hz: Double? {
        guard intervals.count >= 20 else { return nil }
        let s = intervals.sorted()
        return 1 / s[s.count / 2]
    }

    public var jitterMs: Double? {
        guard intervals.count >= 20 else { return nil }
        let ms = intervals.map { $0 * 1000 }
        let mean = ms.reduce(0, +) / Double(ms.count)
        let v = ms.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(ms.count)
        return v.squareRoot()
    }

    public static let standard: [Int] = [60, 90, 120, 125, 144, 165, 240, 250, 500, 1000, 2000, 4000, 8000]

    public static func nearestStandard(_ hz: Double) -> Int {
        guard hz > 0 else { return 0 }
        return standard.min { abs(log(Double($0) / hz)) < abs(log(Double($1) / hz)) } ?? Int(hz)
    }
}

public enum DPI {
    public static let cmPerInch = 2.54

    /// Counts per inch
    public static func cpi(counts: Double, inches: Double) -> Double {
        inches > 0 ? counts / inches : 0
    }

    public static func inches(fromCentimeters cm: Double) -> Double { cm / cmPerInch }

    public static let common: [Int] = [400, 800, 1200, 1600, 2400, 3200, 4000, 6400]

    public static func nearestCommon(_ cpi: Double) -> Int {
        common.min { abs(Double($0) - cpi) < abs(Double($1) - cpi) } ?? Int(cpi)
    }
}
