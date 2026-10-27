import XCTest
@testable import FluentCore

final class LessonTests: XCTestCase {
    func testClickRunStopsAtDuration() {
        var r = ClickRun(duration: 2)
        XCTAssertTrue(r.click(at: 10))
        XCTAssertTrue(r.click(at: 10.5))
        XCTAssertFalse(r.click(at: 12.1))
        XCTAssertEqual(r.count, 2)
        XCTAssertEqual(r.perSecond, [2, 0])
    }

    func testLessonAcceptsGesture() {
        let two = Lesson.all.first { $0.id == "secondary" }!
        XCTAssertTrue(two.accepts(.rightClick))
        XCTAssertTrue(two.accepts(.touch(.tap(fingers: 2))))
        XCTAssertFalse(two.accepts(.click))
        let edge = Lesson.all.first { $0.id == "notification" }!
        XCTAssertTrue(edge.accepts(.touch(.swipe(fingers: 2, direction: .left, fromEdge: true))))
        XCTAssertFalse(edge.accepts(.touch(.swipe(fingers: 2, direction: .left, fromEdge: false))))
    }

    func testDPI() {
        XCTAssertEqual(DPI.cpi(counts: 3200, inches: 2), 1600)
        XCTAssertEqual(DPI.nearestCommon(1500), 1600)
        XCTAssertEqual(PollingEstimator.nearestStandard(980), 1000)
    }
}

final class KeyComboTests: XCTestCase {
    func testParse() {
        XCTAssertEqual(KeyCombo.parse("⇧⌘3"), KeyCombo(key: "3", shift: true, command: true))
        XCTAssertEqual(KeyCombo.parse("⌘Space"), KeyCombo(key: "space", command: true))
        XCTAssertEqual(KeyCombo.parse("⇧⌘?"), KeyCombo(key: "/", shift: true, command: true))
        XCTAssertEqual(KeyCombo.parse("F11"), KeyCombo(key: "f11"))
        XCTAssertEqual(KeyCombo.parse("fn⌫"), KeyCombo(key: "forwarddelete"))
        XCTAssertNil(KeyCombo.parse("⌘←  ⌘→"))
        XCTAssertNil(KeyCombo.parse("⇧⌘4, then Space"))
    }

    func testEventMatch() {
        let e = KeyCombo(keyCode: 20, control: false, option: false, shift: true, command: true)
        XCTAssertEqual(e, KeyCombo.parse("⇧⌘3"))
        XCTAssertEqual(KeyCombo.parse("⌃⌥⇧⌘V")?.labels, ["⌃", "⌥", "⇧", "⌘", "V"])
    }

    func testEveryShortcutIsKnown() {
        for s in MacShortcuts.all where s.detectable { XCTAssertNotNil(s.combo, s.keys) }
        XCTAssertGreaterThan(MacShortcuts.all.filter(\.detectable).count, 30)
    }
}

final class HealthTests: XCTestCase {
    func testBattery() {
        XCTAssertEqual(Health.battery(cycles: 120, capacity: 96), .good)
        XCTAssertEqual(Health.battery(cycles: 1200, capacity: 90), .warn)
        XCTAssertEqual(Health.battery(cycles: 300, capacity: 74), .bad)
        XCTAssertEqual(Health.battery(cycles: nil, capacity: nil), .info)
    }

    func testPercentAndStorage() {
        XCTAssertEqual(Health.percent("92%"), 92)
        XCTAssertNil(Health.percent("n/a"))
        XCTAssertEqual(Health.storage(free: 5, total: 100), .warn)
    }
}
