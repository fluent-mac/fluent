import Foundation

public struct TouchPoint: Equatable, Sendable {
    public var id: Int
    public var x: Double
    public var y: Double

    public init(id: Int, x: Double, y: Double) {
        self.id = id
        self.x = x
        self.y = y
    }
}

public enum SwipeDirection: String, Sendable, Equatable, CaseIterable {
    case up, down, left, right
}

public enum RecognizedGesture: Equatable, Sendable {
    case tap(fingers: Int)
    case swipe(fingers: Int, direction: SwipeDirection, fromEdge: Bool)
    case pinch(fingers: Int, spread: Bool)
    case rotate(fingers: Int, clockwise: Bool)

    public var label: String {
        switch self {
        case .tap(let n): return "\(n)-finger tap"
        case .swipe(let n, let d, let edge): return "\(n)-finger swipe \(d.rawValue)\(edge ? " from the edge" : "")"
        case .pinch(let n, let s): return "\(n)-finger \(s ? "spread" : "pinch")"
        case .rotate(let n, let c): return "\(n)-finger rotate \(c ? "clockwise" : "counterclockwise")"
        }
    }
}

/// Touches to gestures
public struct TouchRecognizer {
    private struct Session {
        var start: Double
        var maxFingers = 0
        var anchorCount = 0
        var anchorX = 0.0
        var anchorY = 0.0
        var anchorSpread = 0.0
        var anchorAngle = 0.0
        var firstX = 0.0
        var travelled = 0.0
        var emitted = false
    }

    private var session: Session?

    /// Physical x
    static let aspect = 1.5

    public init() {}

    public mutating func reset() { session = nil }

    public mutating func update(t: Double, points: [TouchPoint]) -> RecognizedGesture? {
        if points.isEmpty {
            defer { session = nil }
            guard let s = session, !s.emitted, s.maxFingers > 0 else { return nil }
            if t - s.start < 0.4 && s.travelled < 0.05 { return .tap(fingers: s.maxFingers) }
            return nil
        }

        let c = Self.centroid(points)
        let spread = Self.spread(points, around: c)
        let angle = Self.angle(points, around: c)
        var s = session ?? Session(start: t)

        if points.count > s.anchorCount {
            if s.maxFingers == 0 { s.firstX = c.x }
            s.anchorCount = points.count
            s.anchorX = c.x
            s.anchorY = c.y
            s.anchorSpread = spread
            s.anchorAngle = angle
        }
        s.maxFingers = max(s.maxFingers, points.count)
        let dx = (c.x - s.anchorX) * Self.aspect
        let dy = c.y - s.anchorY
        let dist = (dx * dx + dy * dy).squareRoot()
        s.travelled = max(s.travelled, dist)
        session = s

        guard !s.emitted, points.count == s.anchorCount else { return nil }
        let n = points.count
        var result: RecognizedGesture?

        if n >= 2 && dist < 0.12 {
            let ratio = s.anchorSpread > 0.01 ? spread / s.anchorSpread : 1
            if ratio > 1.4 {
                result = .pinch(fingers: n, spread: true)
            } else if ratio < 0.7 {
                result = .pinch(fingers: n, spread: false)
            } else if n == 2 {
                var d = angle - s.anchorAngle
                while d > .pi { d -= 2 * .pi }
                while d < -.pi { d += 2 * .pi }
                if abs(d) > .pi / 6 { result = .rotate(fingers: 2, clockwise: d < 0) }
            }
        }
        if result == nil && dist > 0.22 {
            let dir: SwipeDirection
            if abs(dx) > abs(dy) { dir = dx > 0 ? .right : .left } else { dir = dy > 0 ? .up : .down }
            let edge = (s.firstX > 0.9 && dir == .left) || (s.firstX < 0.1 && dir == .right)
            result = .swipe(fingers: n, direction: dir, fromEdge: edge)
        }
        if result != nil {
            s.emitted = true
            session = s
        }
        return result
    }

    static func centroid(_ p: [TouchPoint]) -> (x: Double, y: Double) {
        let n = Double(p.count)
        return (p.map(\.x).reduce(0, +) / n, p.map(\.y).reduce(0, +) / n)
    }

    static func spread(_ p: [TouchPoint], around c: (x: Double, y: Double)) -> Double {
        let d = p.map { ((($0.x - c.x) * aspect) * (($0.x - c.x) * aspect) + ($0.y - c.y) * ($0.y - c.y)).squareRoot() }
        return d.reduce(0, +) / Double(p.count)
    }

    /// Finger angle
    static func angle(_ p: [TouchPoint], around c: (x: Double, y: Double)) -> Double {
        guard let f = p.min(by: { $0.id < $1.id }) else { return 0 }
        return atan2(f.y - c.y, (f.x - c.x) * aspect)
    }
}
