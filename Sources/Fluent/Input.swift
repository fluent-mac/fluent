import SwiftUI
import AppKit
import FluentCore

typealias EventHandler = @MainActor (NSEvent) -> Void

struct InputHandlers {
    var mouseDown: EventHandler?
    var mouseUp: EventHandler?
    var mouseMoved: EventHandler?
    var scroll: EventHandler?
    var magnify: EventHandler?
    var rotate: EventHandler?
    var smartMagnify: EventHandler?
    var pressure: EventHandler?
    var quickLook: EventHandler?
    var key: (@MainActor (NSEvent, Bool) -> Void)?
    var flags: EventHandler?
    var touches: (@MainActor ([TouchPoint], Double) -> Void)?
}

final class EventView: NSView {
    var h = InputHandlers()
    private var area: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let w = window else { return }
        w.acceptsMouseMovedEvents = true
        w.makeFirstResponder(self)
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = false
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let a = area { removeTrackingArea(a) }
        let a = NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect, .mouseEnteredAndExited], owner: self)
        addTrackingArea(a)
        area = a
    }

    override func mouseDown(with e: NSEvent) { h.mouseDown?(e) }
    override func rightMouseDown(with e: NSEvent) { h.mouseDown?(e) }
    override func otherMouseDown(with e: NSEvent) { h.mouseDown?(e) }
    override func mouseUp(with e: NSEvent) { h.mouseUp?(e) }
    override func rightMouseUp(with e: NSEvent) { h.mouseUp?(e) }
    override func otherMouseUp(with e: NSEvent) { h.mouseUp?(e) }
    override func mouseMoved(with e: NSEvent) { h.mouseMoved?(e) }
    override func mouseDragged(with e: NSEvent) { h.mouseMoved?(e) }
    override func scrollWheel(with e: NSEvent) { h.scroll?(e) }
    override func magnify(with e: NSEvent) { h.magnify?(e) }
    override func rotate(with e: NSEvent) { h.rotate?(e) }
    override func smartMagnify(with e: NSEvent) { h.smartMagnify?(e) }
    override func pressureChange(with e: NSEvent) { h.pressure?(e) }
    override func quickLook(with e: NSEvent) { h.quickLook?(e) }
    override func keyDown(with e: NSEvent) { if h.key != nil { h.key?(e, true) } else { super.keyDown(with: e) } }
    override func keyUp(with e: NSEvent) { if h.key != nil { h.key?(e, false) } else { super.keyUp(with: e) } }
    override func flagsChanged(with e: NSEvent) { h.flags?(e) }

    override func touchesBegan(with e: NSEvent) { emitTouches(e) }
    override func touchesMoved(with e: NSEvent) { emitTouches(e) }
    override func touchesEnded(with e: NSEvent) { emitTouches(e) }
    override func touchesCancelled(with e: NSEvent) { emitTouches(e) }

    private func emitTouches(_ e: NSEvent) {
        guard let f = h.touches else { return }
        let pts = e.touches(matching: .touching, in: self).map {
            TouchPoint(id: abs($0.identity.hash), x: Double($0.normalizedPosition.x), y: Double($0.normalizedPosition.y))
        }
        f(pts, e.timestamp)
    }
}

/// Raw input events
struct EventCapture: NSViewRepresentable {
    var handlers: InputHandlers

    func makeNSView(context: Context) -> EventView {
        let v = EventView()
        v.h = handlers
        return v
    }

    func updateNSView(_ v: EventView, context: Context) { v.h = handlers }
}

enum Feedback {
    static func success() {
        NSSound(named: "Glass")?.play()
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }

    static func tick() {
        NSSound(named: "Tink")?.play()
    }

    static func haptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
}

enum SystemSettings {
    static func open(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:\(pane)") { NSWorkspace.shared.open(url) }
    }

    static let trackpad = "com.apple.Trackpad-Settings.extension"
    static let mouse = "com.apple.Mouse-Settings.extension"
    static let keyboard = "com.apple.Keyboard-Settings.extension"
    static let pointer = "com.apple.Accessibility-Settings.extension"
}
