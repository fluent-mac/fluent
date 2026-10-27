import XCTest
@testable import FluentCore


final class InputTests: XCTestCase {
    private func ramp(_ r: inout TouchRecognizer, fingers: Int, from: (Double, Double), to: (Double, Double), steps: Int = 12, spacing: Double = 0.08) -> [RecognizedGesture] {
        var out: [RecognizedGesture] = []
        for i in 0...steps {
            let f = Double(i) / Double(steps)
            let cx = from.0 + (to.0 - from.0) * f
            let cy = from.1 + (to.1 - from.1) * f
            let pts = (0..<fingers).map { TouchPoint(id: $0, x: cx + (Double($0) - Double(fingers - 1) / 2) * spacing, y: cy) }
            if let g = r.update(t: Double(i) * 0.016, points: pts) { out.append(g) }
        }
        return out
    }

    func testFourFingerSwipeUp() {
        var r = TouchRecognizer()
        let g = ramp(&r, fingers: 4, from: (0.5, 0.25), to: (0.5, 0.75))
        XCTAssertEqual(g, [.swipe(fingers: 4, direction: .up, fromEdge: false)])
    }

    func testThreeFingerSwipeLeft() {
        var r = TouchRecognizer()
        let g = ramp(&r, fingers: 3, from: (0.75, 0.5), to: (0.25, 0.5))
        XCTAssertEqual(g, [.swipe(fingers: 3, direction: .left, fromEdge: false)])
    }

    func testEdgeSwipe() {
        var r = TouchRecognizer()
        let g = ramp(&r, fingers: 2, from: (0.96, 0.5), to: (0.55, 0.5), spacing: 0.02)
        XCTAssertEqual(g, [.swipe(fingers: 2, direction: .left, fromEdge: true)])
    }

    func testTap() {
        var r = TouchRecognizer()
        XCTAssertNil(r.update(t: 0, points: [TouchPoint(id: 1, x: 0.5, y: 0.5)]))
        XCTAssertEqual(r.update(t: 0.1, points: []), .tap(fingers: 1))
    }

    func testHeldTouchIsNotATap() {
        var r = TouchRecognizer()
        _ = r.update(t: 0, points: [TouchPoint(id: 1, x: 0.5, y: 0.5)])
        XCTAssertNil(r.update(t: 0.9, points: []))
    }

    func testSpreadAndPinch() {
        var r = TouchRecognizer()
        var out: [RecognizedGesture] = []
        for i in 0...10 {
            let d = 0.05 + Double(i) * 0.03
            if let g = r.update(t: Double(i) * 0.016, points: [TouchPoint(id: 0, x: 0.5 - d, y: 0.5), TouchPoint(id: 1, x: 0.5 + d, y: 0.5)]) { out.append(g) }
        }
        XCTAssertEqual(out, [.pinch(fingers: 2, spread: true)])
        _ = r.update(t: 1, points: [])
        out = []
        for i in 0...10 {
            let d = 0.35 - Double(i) * 0.03
            if let g = r.update(t: 2 + Double(i) * 0.016, points: [TouchPoint(id: 0, x: 0.5 - d, y: 0.5), TouchPoint(id: 1, x: 0.5 + d, y: 0.5)]) { out.append(g) }
        }
        XCTAssertEqual(out, [.pinch(fingers: 2, spread: false)])
    }

    func testRotate() {
        var r = TouchRecognizer()
        var out: [RecognizedGesture] = []
        for i in 0...10 {
            let a = Double(i) * (.pi / 2 / 10)
            let rad = 0.1
            let p0 = TouchPoint(id: 0, x: 0.5 + cos(a) * rad / 1.5, y: 0.5 + sin(a) * rad)
            let p1 = TouchPoint(id: 1, x: 0.5 - cos(a) * rad / 1.5, y: 0.5 - sin(a) * rad)
            if let g = r.update(t: Double(i) * 0.016, points: [p0, p1]) { out.append(g) }
        }
        XCTAssertEqual(out, [.rotate(fingers: 2, clockwise: false)])
    }

    func testLessonsMatch() {
        let mission = Lesson.all.first { $0.id == "mission" }!
        XCTAssertTrue(mission.accepts(.touch(.swipe(fingers: 4, direction: .up, fromEdge: false))))
        XCTAssertTrue(mission.accepts(.touch(.swipe(fingers: 3, direction: .up, fromEdge: false))))
        XCTAssertFalse(mission.accepts(.touch(.swipe(fingers: 2, direction: .up, fromEdge: false))))
        XCTAssertFalse(mission.accepts(.touch(.swipe(fingers: 4, direction: .down, fromEdge: false))))
        let ids = Lesson.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testClickRun() {
        var run = ClickRun(duration: 5)
        for i in 0..<20 { run.click(at: 100 + Double(i) * 0.1) }
        XCTAssertEqual(run.count, 20)
        XCTAssertEqual(run.peak, 10)
        XCTAssertEqual(run.perSecond.reduce(0, +), 20)
        XCTAssertEqual(run.cps, 4, accuracy: 0.001)
        XCTAssertFalse(run.click(at: 106))
        XCTAssertEqual(run.count, 20)
    }

    func testPolling() {
        var p = PollingEstimator()
        for i in 0..<100 { p.add(Double(i) * 0.001) }
        XCTAssertEqual(p.hz!, 1000, accuracy: 1)
        XCTAssertEqual(PollingEstimator.nearestStandard(p.hz!), 1000)
        XCTAssertEqual(PollingEstimator.nearestStandard(130), 125)
    }

    func testDPI() {
        XCTAssertEqual(DPI.cpi(counts: 4000, inches: DPI.inches(fromCentimeters: 12.7)), 800, accuracy: 0.01)
        XCTAssertEqual(DPI.nearestCommon(790), 800)
    }

    func testShortcutSearch() {
        XCTAssertFalse(MacShortcuts.search("screenshot").isEmpty)
        XCTAssertEqual(MacShortcuts.search("").count, MacShortcuts.all.count)
    }
}
