import Foundation

public enum KeyboardLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case qwerty, dvorak, colemak, workman

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .qwerty: return "QWERTY"
        case .dvorak: return "Dvorak"
        case .colemak: return "Colemak"
        case .workman: return "Workman"
        }
    }

    public var rows: [[Character]] {
        let r: [String]
        switch self {
        case .qwerty: r = ["qwertyuiop", "asdfghjkl;", "zxcvbnm,./"]
        case .dvorak: r = ["',.pyfgcrl", "aoeuidhtns", ";qjkxbmwvz"]
        case .colemak: r = ["qwfpgjluy;", "arstdhneio", "zxcvbkm,./"]
        case .workman: r = ["qdrwbjfup;", "ashtgyneoi", "zxmcvkl,./"]
        }
        return r.map(Array.init)
    }

    /// Row indent
    public static let stagger: [Double] = [0, 0.3, 0.8]
}
