import SwiftUI
import FluentCore

/// Touched cells light
struct SurfaceView: View {
    private let cols = 16
    private let rows = 10
    @State private var hit: Set<Int> = []
    @State private var live: [TouchPoint] = []

    var body: some View {
        VStack(spacing: 22) {
            Text("\(hit.count) of \(cols * rows)")
                .font(.system(size: 40, weight: .semibold, design: .rounded)).monospacedDigit()
            Canvas { g, size in
                let w = size.width / Double(cols), h = size.height / Double(rows)
                for i in 0..<(cols * rows) {
                    let r = CGRect(x: Double(i % cols) * w + 1, y: Double(i / cols) * h + 1, width: w - 2, height: h - 2)
                    g.fill(Path(roundedRect: r, cornerRadius: 4), with: .color(hit.contains(i) ? Color.accentColor : Color.primary.opacity(0.08)))
                }
            }
            .aspectRatio(1.6, contentMode: .fit)
            .frame(maxWidth: 640)
            .overlay(EventCapture(handlers: handlers))
            .accessibilityLabel("Trackpad surface test, \(hit.count) of \(cols * rows) areas touched")
            if hit.count == cols * rows {
                Label("Every area responded", systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.title3)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Trackpad Surface")
        .toolbar { ToolbarItem { Button("Reset") { hit = [] } } }
    }

    private var handlers: InputHandlers {
        var h = InputHandlers()
        h.touches = { pts, _ in
            live = pts
            for p in pts {
                let c = min(cols - 1, max(0, Int(p.x * Double(cols))))
                let r = min(rows - 1, max(0, Int((1 - p.y) * Double(rows))))
                hit.insert(r * cols + c)
            }
        }
        return h
    }
}
