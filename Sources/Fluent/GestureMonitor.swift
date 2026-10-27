import SwiftUI
import AppKit
import FluentCore

/// Events to gestures
@MainActor
final class GestureMonitor: ObservableObject {
    @Published private(set) var touches: [TouchPoint] = []
    @Published private(set) var recent: [GestureInput] = []
    var onInput: ((GestureInput) -> Void)?

    private var recognizer = TouchRecognizer()
    private var scroll = (x: 0.0, y: 0.0, sent: false)
    private var zoom = (sum: 0.0, sent: false)
    private var turn = (sum: 0.0, sent: false)
    private var stage = 0

    var last: GestureInput? { recent.first }

    func clear() {
        recent = []
        touches = []
        recognizer.reset()
    }

    private func emit(_ g: GestureInput) {
        recent = Array(([g] + recent).prefix(6))
        onInput?(g)
    }

    var handlers: InputHandlers {
        var h = InputHandlers()
        h.mouseDown = { [weak self] e in
            guard let self else { return }
            switch e.type {
            case .rightMouseDown: emit(.rightClick)
            case .leftMouseDown: emit(e.modifierFlags.contains(.control) ? .rightClick : .click)
            default: break
            }
        }
        h.quickLook = { [weak self] _ in self?.emit(.lookUp) }
        h.smartMagnify = { [weak self] _ in self?.emit(.smartZoom) }
        h.pressure = { [weak self] e in
            guard let self else { return }
            if e.stage == 2 && stage < 2 { emit(.forceClick) }
            stage = e.stage
        }
        h.scroll = { [weak self] e in self?.onScroll(e) }
        h.magnify = { [weak self] e in self?.onMagnify(e) }
        h.rotate = { [weak self] e in self?.onRotate(e) }
        h.touches = { [weak self] pts, t in
            guard let self else { return }
            touches = pts
            if let g = recognizer.update(t: t, points: pts) { emit(.touch(g)) }
        }
        return h
    }

    private func onScroll(_ e: NSEvent) {
        guard e.momentumPhase.isEmpty else { return }
        if !e.hasPreciseScrollingDeltas {
            // no wheel phases
            let dy = e.scrollingDeltaY, dx = e.scrollingDeltaX
            if dx != 0 || dy != 0 { emit(.scroll(vertical: abs(dy) >= abs(dx))) }
            return
        }
        if e.phase.contains(.began) || e.phase.contains(.mayBegin) { scroll = (0, 0, false) }
        scroll.x += e.scrollingDeltaX
        scroll.y += e.scrollingDeltaY
        if !scroll.sent && max(abs(scroll.x), abs(scroll.y)) > 40 {
            scroll.sent = true
            emit(.scroll(vertical: abs(scroll.y) >= abs(scroll.x)))
        }
        if e.phase.contains(.ended) || e.phase.contains(.cancelled) { scroll = (0, 0, false) }
    }

    private func onMagnify(_ e: NSEvent) {
        if e.phase.contains(.began) { zoom = (0, false) }
        zoom.sum += e.magnification
        if !zoom.sent && abs(zoom.sum) > 0.1 {
            zoom.sent = true
            emit(.magnify(spread: zoom.sum > 0))
        }
        if e.phase.contains(.ended) || e.phase.contains(.cancelled) { zoom = (0, false) }
    }

    private func onRotate(_ e: NSEvent) {
        if e.phase.contains(.began) { turn = (0, false) }
        turn.sum += Double(e.rotation)
        if !turn.sent && abs(turn.sum) > 15 {
            turn.sent = true
            emit(.rotation)
        }
        if e.phase.contains(.ended) || e.phase.contains(.cancelled) { turn = (0, false) }
    }
}
