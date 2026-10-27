import Foundation

public enum WordBank {
    public static let common: [String] = """
    the be to of and a in that have it for not on with he as you do at this but his by from they we say her she or an will my one all would there their what so up out if about who get which go me when make can like time no just him know take people into year your good some could them see other than then now look only come its over think also back after use two how our work first well way even new want because any these give day most us great between need large often hand high place hold turn move live point city play small number off always next night read open seem together follow begin life water room mother area money story young fact month different lot right study book eye job word though business issue side kind four head far black long both little house yes after since long provide service around friend important father sit away until power town white real stop idea child school keep never start city earth light thought head under story saw left don't few while along might close something seem next hard example ease paper group often run important until children side feet car mile night walk sea began grow took river state once book hear stop without second later miss idea enough eat face watch far indian really almost let above girl sometimes mountain cut young talk soon list song being leave family body music color stand sun question fish area mark horse birds problem complete room knew since ever piece told usually friends easy heard order red door sure become top ship across today during short better best however low hours black products happened whole measure remember early waves reached listen wind rock space covered fast several hold himself toward five step morning passed vowel true hundred against pattern numeral table north slowly money map farm pulled draw voice seen cold cried plan notice south sing war ground fall king town unit figure certain field travel wood fire upon done english road half ten fly gave box finally wait correct oh quickly person became shown minutes strong verb stars front feel fact inches street decided contain course surface produce building ocean class note nothing rest carefully scientists inside wheels stay green known island week less machine base ago stood plane system behind ran round boat game force brought understand warm common bring explain dry though language shape deep thousands yes clear equation yet government filled heat full hot check object am rule among noun power cannot able six size dark ball material special heavy fine pair circle include built
    """.split(whereSeparator: { $0 == " " || $0.isNewline }).map(String.init).filter { !$0.contains("'") }

    public static let sentences: [String] = [
        "A rolling stone gathers no moss.",
        "Actions speak louder than words.",
        "All that glitters is not gold.",
        "Better late than never.",
        "Fortune favors the bold.",
        "Great oaks from little acorns grow.",
        "Haste makes waste.",
        "Look before you leap.",
        "Many hands make light work.",
        "Practice makes perfect.",
        "The early bird catches the worm.",
        "The pen is mightier than the sword.",
        "There is no place like home.",
        "Time and tide wait for no one.",
        "Two heads are better than one.",
        "When in Rome, do as the Romans do.",
        "You cannot judge a book by its cover.",
        "A journey of a thousand miles begins with a single step.",
        "Every cloud has a silver lining.",
        "Slow and steady wins the race.",
        "Where there is smoke, there is fire.",
        "Do not count your chickens before they hatch.",
        "Birds of a feather flock together.",
        "Necessity is the mother of invention.",
        "A watched pot never boils.",
        "Do not put all your eggs in one basket.",
        "The quick brown fox jumps over the lazy dog.",
        "Strike while the iron is hot.",
        "Rome was not built in a day.",
        "The grass is always greener on the other side.",
    ]
}

public struct TextOptions: Equatable, Sendable {
    public var punctuation: Bool
    public var numbers: Bool

    public init(punctuation: Bool = false, numbers: Bool = false) {
        self.punctuation = punctuation
        self.numbers = numbers
    }
}

public enum TextGenerator {
    public static func words<G: RandomNumberGenerator>(count: Int, options: TextOptions, using g: inout G) -> String {
        var out: [String] = []
        var prev = ""
        var capitalizeNext = options.punctuation
        for i in 0..<max(count, 1) {
            var w: String
            if options.numbers && Int.random(in: 0..<10, using: &g) == 0 {
                w = String(Int.random(in: 1...9999, using: &g))
            } else {
                repeat { w = WordBank.common.randomElement(using: &g)! } while w == prev
            }
            prev = w
            if capitalizeNext {
                w = w.prefix(1).uppercased() + w.dropFirst()
                capitalizeNext = false
            }
            if options.punctuation && i < count - 1 {
                let roll = Int.random(in: 0..<100, using: &g)
                switch roll {
                case 0..<10: w += ","
                case 10..<16: w += "."; capitalizeNext = true
                case 16..<18: w += "?"; capitalizeNext = true
                case 18..<19: w += "!"; capitalizeNext = true
                case 19..<21: w += ";"
                default: break
                }
            }
            out.append(w)
        }
        if options.punctuation, let last = out.last, let c = last.last, c.isLetter || c.isNumber {
            out[out.count - 1] += "."
        }
        return out.joined(separator: " ")
    }

    public static func sentences<G: RandomNumberGenerator>(count: Int, using g: inout G) -> String {
        WordBank.sentences.shuffled(using: &g).prefix(count).joined(separator: " ")
    }

    /// Words by letters
    public static func drill<G: RandomNumberGenerator>(weak: [Character], count: Int, using g: inout G) -> String {
        let set = Set(weak)
        let scored = WordBank.common
            .map { w in (w, w.filter { set.contains($0) }.count) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
        let pool = scored.prefix(120).map(\.0)
        guard pool.count >= 8 else { return words(count: count, options: TextOptions(), using: &g) }
        var out: [String] = []
        var prev = ""
        while out.count < count {
            let w = pool.randomElement(using: &g)!
            if w != prev { out.append(w); prev = w }
        }
        return out.joined(separator: " ")
    }

    /// Cleans text
    public static func normalize(_ s: String) -> String {
        let map: [Character: String] = [
            "\u{2018}": "'", "\u{2019}": "'", "\u{201C}": "\"", "\u{201D}": "\"",
            "\u{2013}": "-", "\u{2014}": "-", "\u{2026}": "...", "\u{00A0}": " ",
        ]
        var out = ""
        for ch in s {
            if let r = map[ch] {
                out += r
            } else if ch.isNewline || ch == "\t" {
                out += " "
            } else if ch.unicodeScalars.allSatisfy({ $0.value >= 32 && $0.value != 127 }) {
                out.append(ch)
            }
        }
        return out.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
    }
}
