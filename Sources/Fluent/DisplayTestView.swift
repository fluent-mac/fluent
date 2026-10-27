import SwiftUI
import AppKit

@MainActor
final class PatternState: ObservableObject {
    @Published var index = 0
    static let count = 9
}

final class TestWindow: NSWindow {
    var state: PatternState?
    var onClose: (() -> Void)?
    override var canBecomeKey: Bool { true }

    override func keyDown(with e: NSEvent) {
        switch e.keyCode {
        case 53: onClose?()
        case 123, 126: state?.index = max(0, (state?.index ?? 0) - 1)
        default: advance()
        }
    }

    override func mouseDown(with e: NSEvent) { advance() }

    private func advance() {
        guard let s = state else { return }
        if s.index + 1 >= PatternState.count { onClose?() } else { s.index += 1 }
    }
}

struct PatternView: View {
    @ObservedObject var state: PatternState

    var body: some View {
        switch state.index {
        case 0: Color.white
        case 1: Color.black
        case 2: Color.red
        case 3: Color.green
        case 4: Color.blue
        case 5: Color(white: 0.5)
        case 6: LinearGradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple], startPoint: .leading, endPoint: .trailing)
        case 7: LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)
        default:
            Canvas { g, size in
                g.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                var x = 0.0
                while x < size.width {
                    g.fill(Path(CGRect(x: x, y: 0, width: 1, height: size.height)), with: .color(.white))
                    x += 2
                }
            }
        }
    }
}

@MainActor
enum DisplayTest {
    private static var window: TestWindow?

    static func start() {
        guard window == nil, let screen = NSScreen.main else { return }
        let state = PatternState()
        let w = TestWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        w.state = state
        w.onClose = { stop() }
        w.level = .screenSaver
        w.contentView = NSHostingView(rootView: PatternView(state: state).ignoresSafeArea())
        w.makeKeyAndOrderFront(nil)
        window = w
    }

    static func stop() {
        window?.orderOut(nil)
        window = nil
    }
}

struct DisplayTestView: View {
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "display").font(.system(size: 64)).foregroundStyle(.secondary)
            Text("Display Test").font(.largeTitle.weight(.semibold))
            Text("Full-screen colors, a gradient and fine lines. Look for dead pixels, stuck pixels, marks and uneven backlight.")
                .font(.title3).multilineTextAlignment(.center).frame(maxWidth: 460)
            Button("Start") { DisplayTest.start() }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            Text("Click or press any key for the next pattern. Esc leaves.")
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Display Test")
    }
}
