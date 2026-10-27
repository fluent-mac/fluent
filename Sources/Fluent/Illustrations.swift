import SwiftUI
import AppKit
import FluentCore

struct Finger {
    var x: Double
    var y: Double
    var scale = 1.0
    var opacity = 1.0
    var ring: Double?
}

/// Finger positions
enum GestureMotion {
    static func clamp(_ x: Double) -> Double { min(1, max(0, x)) }

    static func ease(_ x: Double) -> Double {
        let x = clamp(x)
        return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }

    static func fade(_ t: Double) -> Double { clamp(min(t / 0.12, (0.94 - t) / 0.1)) }

    static func pulse(_ t: Double, at: Double) -> Double? {
        let p = (t - at) / 0.3
        return p >= 0 && p <= 1 ? p : nil
    }

    static func offsets(_ n: Int) -> [Double] {
        (0..<n).map { (Double($0) - Double(n - 1) / 2) * 0.14 }
    }

    static func fingers(_ demo: GestureDemo, _ t: Double) -> [Finger] {
        let o = fade(t)
        switch demo {
        case .click: return taps(1, [0.35], t, o)
        case .tap(let n): return taps(n, [0.35], t, o)
        case .doubleTap(let n): return taps(n, [0.3, 0.56], t, o)
        case .press:
            let g = ease((t - 0.25) / 0.45)
            return [Finger(x: 0.5, y: 0.5, scale: 1 + 0.45 * g, opacity: o, ring: g > 0.9 ? (t * 4).truncatingRemainder(dividingBy: 1) : nil)]
        case .swipe(let n, let d):
            let v: (Double, Double)
            switch d {
            case .up: v = (0, -1)
            case .down: v = (0, 1)
            case .left: v = (-1, 0)
            case .right: v = (1, 0)
            }
            return move(n, v, t, o, center: (0.5, 0.5), span: 0.5)
        case .scroll(let vertical):
            return move(2, vertical ? (0, -1) : (-1, 0), t, o, center: (0.5, 0.5), span: 0.46)
        case .edgeSwipe:
            return move(2, (-1, 0), t, o, center: (0.735, 0.5), span: 0.47)
        case .pinch(let n, let spread):
            let p = ease((t - 0.15) / 0.6)
            let r = spread ? 0.12 + 0.3 * p : 0.42 - 0.3 * p
            return (0..<n).map { i in
                let a = Double(i) * 2 * .pi / Double(n) + (n == 2 ? .pi / 4 : -.pi / 2)
                return Finger(x: 0.5 + cos(a) * r / 1.5, y: 0.5 + sin(a) * r, opacity: o)
            }
        case .rotate:
            let p = ease((t - 0.15) / 0.6)
            let a0 = -.pi / 3 + p * .pi * 0.55
            return [0.0, .pi].map { off in
                Finger(x: 0.5 + cos(a0 + off) * 0.3 / 1.5, y: 0.5 + sin(a0 + off) * 0.3, opacity: o)
            }
        }
    }

    private static func taps(_ n: Int, _ times: [Double], _ t: Double, _ o: Double) -> [Finger] {
        let hit = times.compactMap { pulse(t, at: $0) }.first
        let down = hit.map { 1 - 0.2 * sin($0 * .pi) } ?? 1
        return offsets(n).map { Finger(x: 0.5 + $0, y: 0.5, scale: down, opacity: o, ring: hit) }
    }

    private static func move(_ n: Int, _ v: (Double, Double), _ t: Double, _ o: Double, center: (Double, Double), span: Double) -> [Finger] {
        let p = ease((t - 0.15) / 0.6)
        var out: [Finger] = []
        for g in (0..<3).reversed() {
            let k = (max(0, p - Double(g) * 0.07) - 0.5) * span
            for off in offsets(n) {
                let across = v.0 == 0 ? (off, 0.0) : (0.0, off * 1.5)
                out.append(Finger(
                    x: center.0 + v.0 * k + across.0,
                    y: center.1 + v.1 * k * 1.5 + across.1,
                    scale: 1 - Double(g) * 0.12,
                    opacity: o * (1 - Double(g) * 0.35)))
            }
        }
        return out
    }
}

/// Looping trackpad fingers
struct GestureIllustration: View {
    let demo: GestureDemo
    @Environment(\.accessibilityReduceMotion) private var still
    private let period = 2.4

    var body: some View {
        TimelineView(.animation(paused: still)) { ctx in
            let t = still ? 0.55 : ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            Canvas { g, size in
                let r = size.height * 0.085
                for f in GestureMotion.fingers(demo, t) {
                    let c = CGPoint(x: f.x * size.width, y: f.y * size.height)
                    if let ring = f.ring {
                        let rr = r * (1 + 1.6 * ring)
                        g.stroke(
                            Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)),
                            with: .color(Color.accentColor.opacity(0.55 * (1 - ring))), lineWidth: 3)
                    }
                    let rd = r * f.scale
                    g.fill(
                        Path(ellipseIn: CGRect(x: c.x - rd, y: c.y - rd, width: rd * 2, height: rd * 2)),
                        with: .color(Color.accentColor.opacity(0.85 * f.opacity)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct Keycap: View {
    let label: String
    var pressed = 0.0

    var body: some View {
        Text(label)
            .font(.system(size: 30, weight: .medium, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, label.count > 2 ? 18 : 0)
            .frame(minWidth: 84, minHeight: 84)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.primary.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.accentColor.opacity(0.6 * pressed)))
            }
            .shadow(color: .black.opacity(0.4 * (1 - pressed)), radius: 0, y: 7 * (1 - pressed))
            .offset(y: 7 * pressed)
    }
}

/// Pressing keycaps
struct ShortcutIllustration: View {
    let keys: String
    @Environment(\.accessibilityReduceMotion) private var still
    private let period = 2.2

    private var caps: [String] { KeyCombo.parse(keys)?.labels ?? [keys] }

    var body: some View {
        TimelineView(.animation(paused: still)) { ctx in
            let t = still ? 0.6 : ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            HStack(spacing: 14) {
                ForEach(Array(caps.enumerated()), id: \.offset) { i, c in
                    let at = 0.12 + 0.12 * Double(i)
                    let down = GestureMotion.clamp((t - at) / 0.06) * GestureMotion.clamp((0.86 - t) / 0.06)
                    Keycap(label: c, pressed: down)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct CheckShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.15, y: r.minY + r.height * 0.52))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.4, y: r.minY + r.height * 0.75))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.85, y: r.minY + r.height * 0.28))
        return p
    }
}

/// Green check
struct SuccessMark: View {
    @Environment(\.accessibilityReduceMotion) private var still
    @State private var shown = false
    @State private var ripple = false
    @State private var check = 0.0

    var body: some View {
        ZStack {
            Circle().stroke(Color.green.opacity(0.6), lineWidth: 4)
                .scaleEffect(ripple ? 2.1 : 1)
                .opacity(ripple ? 0 : 0.9)
            Circle().fill(Color.green)
                .scaleEffect(shown ? 1 : 0.2)
            CheckShape()
                .trim(from: 0, to: check)
                .stroke(.white, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                .padding(28)
        }
        .frame(width: 112, height: 112)
        .accessibilityLabel("Done")
        .onAppear {
            if still {
                shown = true
                check = 1
                return
            }
            withAnimation(.spring(duration: 0.35, bounce: 0.35)) { shown = true }
            withAnimation(.easeOut(duration: 0.35).delay(0.2)) { check = 1 }
            withAnimation(.easeOut(duration: 0.7).delay(0.25)) { ripple = true }
        }
    }
}
