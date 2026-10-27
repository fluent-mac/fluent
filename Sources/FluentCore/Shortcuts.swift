import Foundation

public struct MacShortcut: Identifiable, Sendable, Hashable {
    public let category: String
    public let action: String
    public let keys: String
    public var id: String { category + action }
}

public enum MacShortcuts {
    private static func s(_ c: String, _ a: String, _ k: String) -> MacShortcut {
        MacShortcut(category: c, action: a, keys: k)
    }

    public static let all: [MacShortcut] = [
        s("Screenshots", "Capture the whole screen", "⇧⌘3"),
        s("Screenshots", "Capture a selection", "⇧⌘4"),
        s("Screenshots", "Capture a window", "⇧⌘4, then Space"),
        s("Screenshots", "Open screenshot and recording options", "⇧⌘5"),
        s("Screenshots", "Copy to the clipboard instead of a file", "Add ⌃ to any screenshot shortcut"),

        s("System", "Open Spotlight", "⌘Space"),
        s("System", "Switch to the next app", "⌘Tab"),
        s("System", "Switch between windows of one app", "⌘`"),
        s("System", "Force quit an app", "⌥⌘Esc"),
        s("System", "Lock the screen", "⌃⌘Q"),
        s("System", "Open the emoji and symbols picker", "⌃⌘Space"),
        s("System", "Show Mission Control", "⌃↑"),
        s("System", "Show windows of the current app", "⌃↓"),
        s("System", "Move to the next space", "⌃→"),
        s("System", "Move to the previous space", "⌃←"),
        s("System", "Show the desktop", "F11"),
        s("System", "Open Settings in the current app", "⌘,"),

        s("Windows and apps", "Close the window", "⌘W"),
        s("Windows and apps", "Close every window of the app", "⌥⌘W"),
        s("Windows and apps", "Minimize the window", "⌘M"),
        s("Windows and apps", "Hide the app", "⌘H"),
        s("Windows and apps", "Hide all other apps", "⌥⌘H"),
        s("Windows and apps", "Quit the app", "⌘Q"),
        s("Windows and apps", "Enter or leave full screen", "⌃⌘F"),
        s("Windows and apps", "Open a new window or document", "⌘N"),
        s("Windows and apps", "Open a file", "⌘O"),
        s("Windows and apps", "Save", "⌘S"),
        s("Windows and apps", "Print", "⌘P"),
        s("Windows and apps", "Open the Help menu search", "⇧⌘?"),

        s("Editing", "Undo", "⌘Z"),
        s("Editing", "Redo", "⇧⌘Z"),
        s("Editing", "Cut", "⌘X"),
        s("Editing", "Copy", "⌘C"),
        s("Editing", "Paste", "⌘V"),
        s("Editing", "Paste and match the surrounding style", "⌥⇧⌘V"),
        s("Editing", "Select all", "⌘A"),
        s("Editing", "Find", "⌘F"),
        s("Editing", "Find next", "⌘G"),
        s("Editing", "Bold", "⌘B"),
        s("Editing", "Italic", "⌘I"),
        s("Editing", "Underline", "⌘U"),

        s("Text navigation", "Move one word left or right", "⌥←  ⌥→"),
        s("Text navigation", "Move to the start or end of the line", "⌘←  ⌘→"),
        s("Text navigation", "Move to the start or end of the document", "⌘↑  ⌘↓"),
        s("Text navigation", "Move to the start or end of the line (Emacs style)", "⌃A  ⌃E"),
        s("Text navigation", "Delete the previous word", "⌥⌫"),
        s("Text navigation", "Delete to the start of the line", "⌘⌫"),
        s("Text navigation", "Delete forward", "fn⌫"),
        s("Text navigation", "Delete to the end of the line", "⌃K"),
        s("Text navigation", "Page up or down", "fn↑  fn↓"),
        s("Text navigation", "Select while moving", "Hold ⇧ with any movement key"),

        s("Finder", "Open the selected item", "⌘O"),
        s("Finder", "Show Get Info", "⌘I"),
        s("Finder", "Preview with Quick Look", "Space"),
        s("Finder", "Duplicate", "⌘D"),
        s("Finder", "Make an alias", "⌃⌘A"),
        s("Finder", "Move to the Trash", "⌘⌫"),
        s("Finder", "Empty the Trash", "⇧⌘⌫"),
        s("Finder", "Create a new folder", "⇧⌘N"),
        s("Finder", "Go to a folder by path", "⇧⌘G"),
        s("Finder", "Open the Home folder", "⇧⌘H"),
        s("Finder", "Open Downloads", "⌥⌘L"),
        s("Finder", "Show or hide hidden files", "⇧⌘."),
        s("Finder", "Go up one folder", "⌘↑"),
        s("Finder", "Go back or forward", "⌘[  ⌘]"),

        s("Safari", "Open a new tab", "⌘T"),
        s("Safari", "Reopen the last closed tab", "⇧⌘T"),
        s("Safari", "Jump to the address bar", "⌘L"),
        s("Safari", "Reload the page", "⌘R"),
        s("Safari", "Show all tabs", "⇧⌘\\"),
        s("Safari", "Go to the next tab", "⌃Tab"),
        s("Safari", "Open the Web Inspector", "⌥⌘I"),
    ]

    public static var categories: [String] {
        var seen: [String] = []
        for sc in all where !seen.contains(sc.category) { seen.append(sc.category) }
        return seen
    }

    public static func search(_ q: String) -> [MacShortcut] {
        let t = q.trimmingCharacters(in: .whitespaces).lowercased()
        guard !t.isEmpty else { return all }
        return all.filter { $0.action.lowercased().contains(t) || $0.keys.lowercased().contains(t) || $0.category.lowercased().contains(t) }
    }
}
