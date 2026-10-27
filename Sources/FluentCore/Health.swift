import Foundation

public enum Level: Sendable, Equatable {
    case good, warn, bad, info
}

/// Mac Check thresholds
public enum Health {
    public static func battery(cycles: Int?, capacity: Int?) -> Level {
        if let c = capacity, c < 80 { return .bad }
        if let n = cycles, n >= 1000 { return .warn }
        if let c = capacity, c < 85 { return .warn }
        return cycles == nil && capacity == nil ? .info : .good
    }

    public static func storage(free: Int64, total: Int64) -> Level {
        guard total > 0 else { return .info }
        return Double(free) / Double(total) < 0.1 ? .warn : .good
    }

    /// Leading integer
    public static func percent(_ s: String?) -> Int? {
        guard let s else { return nil }
        let digits = s.prefix { $0.isNumber }
        return Int(digits)
    }
}
