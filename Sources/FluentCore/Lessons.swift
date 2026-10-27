import Foundation

/// Observed habit
public enum GestureInput: Equatable, Sendable {
    case touch(RecognizedGesture)
    case click
    case rightClick
    case lookUp
    case smartZoom
    case forceClick
    case scroll(vertical: Bool)
    case magnify(spread: Bool)
    case rotation

    public var label: String {
        switch self {
        case .touch(let g): return g.label
        case .click: return "Click"
        case .rightClick: return "Secondary click"
        case .lookUp: return "Look up"
        case .smartZoom: return "Smart zoom"
        case .forceClick: return "Force click"
        case .scroll(let v): return v ? "Vertical scroll" : "Horizontal scroll"
        case .magnify(let s): return s ? "Zoom in" : "Zoom out"
        case .rotation: return "Rotate"
        }
    }
}

public enum GestureDemo: Equatable, Sendable {
    case click
    case tap(Int)
    case doubleTap(Int)
    case press
    case swipe(Int, SwipeDirection)
    case pinch(Int, spread: Bool)
    case rotate
    case scroll(vertical: Bool)
    case edgeSwipe
}

public struct Lesson: Identifiable, Sendable {
    public let id: String
    public let group: String
    public let title: String
    public let hint: String
    public let effect: String
    public let setting: String
    public let pane: String
    public let demo: GestureDemo
    public let accepts: @Sendable (GestureInput) -> Bool

    public static let trackpad = "com.apple.Trackpad-Settings.extension"

    public static let all: [Lesson] = [
        Lesson(
            id: "click", group: "Point and click", title: "Click",
            hint: "Press down on the trackpad until it clicks.",
            effect: "Selects whatever is under the pointer.",
            setting: "Trackpad, Point & Click", pane: trackpad, demo: .click,
            accepts: { $0 == .click }),
        Lesson(
            id: "tap", group: "Point and click", title: "Tap with one finger",
            hint: "Touch the trackpad lightly with one finger without pressing down.",
            effect: "Works like a click when Tap to Click is on.",
            setting: "Trackpad, Point & Click, Tap to click", pane: trackpad, demo: .tap(1),
            accepts: { $0 == .touch(.tap(fingers: 1)) }),
        Lesson(
            id: "secondary", group: "Point and click", title: "Secondary click",
            hint: "Click or tap with two fingers.",
            effect: "Opens the shortcut menu for the item under the pointer.",
            setting: "Trackpad, Point & Click, Secondary click", pane: trackpad, demo: .tap(2),
            accepts: { $0 == .rightClick || $0 == .touch(.tap(fingers: 2)) }),
        Lesson(
            id: "lookup", group: "Point and click", title: "Look up",
            hint: "Tap with three fingers on a word.",
            effect: "Shows a definition or a preview of what is under the pointer.",
            setting: "Trackpad, Point & Click, Look up & data detectors", pane: trackpad, demo: .tap(3),
            accepts: { $0 == .lookUp || $0 == .touch(.tap(fingers: 3)) }),
        Lesson(
            id: "force", group: "Point and click", title: "Force click",
            hint: "Click, then keep pressing firmly. This needs a Force Touch trackpad.",
            effect: "Shows a preview or extra detail for the item under the pointer.",
            setting: "Trackpad, Point & Click, Force Click and haptic feedback", pane: trackpad, demo: .press,
            accepts: { $0 == .forceClick }),
        Lesson(
            id: "scroll", group: "Scroll and zoom", title: "Scroll",
            hint: "Slide two fingers up or down.",
            effect: "Scrolls the content under the pointer.",
            setting: "Trackpad, Scroll & Zoom, Natural scrolling", pane: trackpad, demo: .scroll(vertical: true),
            accepts: { $0 == .scroll(vertical: true) }),
        Lesson(
            id: "pages", group: "Scroll and zoom", title: "Swipe between pages",
            hint: "Slide two fingers left or right.",
            effect: "Goes back and forward in apps such as Safari.",
            setting: "Trackpad, More Gestures, Swipe between pages", pane: trackpad, demo: .scroll(vertical: false),
            accepts: { $0 == .scroll(vertical: false) }),
        Lesson(
            id: "zoomin", group: "Scroll and zoom", title: "Zoom in",
            hint: "Spread two fingers apart.",
            effect: "Zooms in on photos, maps and web pages.",
            setting: "Trackpad, Scroll & Zoom, Zoom in or out", pane: trackpad, demo: .pinch(2, spread: true),
            accepts: { $0 == .magnify(spread: true) }),
        Lesson(
            id: "zoomout", group: "Scroll and zoom", title: "Zoom out",
            hint: "Pinch two fingers together.",
            effect: "Zooms out again.",
            setting: "Trackpad, Scroll & Zoom, Zoom in or out", pane: trackpad, demo: .pinch(2, spread: false),
            accepts: { $0 == .magnify(spread: false) }),
        Lesson(
            id: "smart", group: "Scroll and zoom", title: "Smart zoom",
            hint: "Double-tap with two fingers.",
            effect: "Zooms into a web page or PDF and back out.",
            setting: "Trackpad, Scroll & Zoom, Smart zoom", pane: trackpad, demo: .doubleTap(2),
            accepts: { $0 == .smartZoom }),
        Lesson(
            id: "rotate", group: "Scroll and zoom", title: "Rotate",
            hint: "Turn two fingers around each other.",
            effect: "Rotates photos and shapes in apps that support it.",
            setting: "Trackpad, Scroll & Zoom, Rotate", pane: trackpad, demo: .rotate,
            accepts: { $0 == .rotation }),
        Lesson(
            id: "notification", group: "System gestures", title: "Notification Center",
            hint: "Start with two fingers off the right edge and slide left.",
            effect: "Opens Notification Center.",
            setting: "Trackpad, More Gestures, Notification Center", pane: trackpad, demo: .edgeSwipe,
            accepts: {
                if case .touch(.swipe(let n, .left, true)) = $0 { return n == 2 }
                return false
            }),
        Lesson(
            id: "mission", group: "System gestures", title: "Mission Control",
            hint: "Swipe up with three or four fingers.",
            effect: "Shows every open window and your spaces.",
            setting: "Trackpad, More Gestures, Mission Control", pane: trackpad, demo: .swipe(4, .up),
            accepts: {
                if case .touch(.swipe(let n, .up, _)) = $0 { return n == 3 || n == 4 }
                return false
            }),
        Lesson(
            id: "expose", group: "System gestures", title: "App Exposé",
            hint: "Swipe down with three or four fingers.",
            effect: "Shows all windows of the app you are using.",
            setting: "Trackpad, More Gestures, App Exposé", pane: trackpad, demo: .swipe(4, .down),
            accepts: {
                if case .touch(.swipe(let n, .down, _)) = $0 { return n == 3 || n == 4 }
                return false
            }),
        Lesson(
            id: "spaces", group: "System gestures", title: "Switch spaces",
            hint: "Swipe left or right with three or four fingers.",
            effect: "Moves between desktops and full-screen apps.",
            setting: "Trackpad, More Gestures, Swipe between full-screen apps", pane: trackpad, demo: .swipe(4, .left),
            accepts: {
                if case .touch(.swipe(let n, let d, _)) = $0 { return (n == 3 || n == 4) && (d == .left || d == .right) }
                return false
            }),
        Lesson(
            id: "launchpad", group: "System gestures", title: "Launchpad",
            hint: "Pinch your thumb and three fingers together.",
            effect: "Opens the app launcher.",
            setting: "Trackpad, More Gestures, Launchpad", pane: trackpad, demo: .pinch(4, spread: false),
            accepts: {
                if case .touch(.pinch(let n, false)) = $0 { return n >= 4 }
                return false
            }),
        Lesson(
            id: "desktop", group: "System gestures", title: "Show Desktop",
            hint: "Spread your thumb and three fingers apart.",
            effect: "Moves every window aside to show the desktop.",
            setting: "Trackpad, More Gestures, Show Desktop", pane: trackpad, demo: .pinch(4, spread: true),
            accepts: {
                if case .touch(.pinch(let n, true)) = $0 { return n >= 4 }
                return false
            }),
    ]
}
