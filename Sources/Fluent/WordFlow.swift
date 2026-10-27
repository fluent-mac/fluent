import SwiftUI

/// Wraps words
struct WordFlow: Layout {
    var activeIndex: Int
    var visibleLines = 3

    private func pitch(_ subviews: Subviews) -> CGFloat {
        (subviews.first?.sizeThatFits(.unspecified).height ?? 40) * 1.3
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 800, height: pitch(subviews) * CGFloat(visibleLines))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let pitch = pitch(subviews)
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var lines = [Int](repeating: 0, count: subviews.count)
        var xs = [CGFloat](repeating: 0, count: subviews.count)
        var x: CGFloat = 0
        var line = 0
        let slack = pitch * 0.45
        for i in subviews.indices {
            if x > 0 && x + sizes[i].width > bounds.width + slack {
                line += 1
                x = 0
            }
            xs[i] = x
            lines[i] = line
            x += sizes[i].width
        }
        let active = min(max(activeIndex, 0), subviews.count - 1)
        let shift = CGFloat(max(0, lines[active] - 1)) * pitch
        for i in subviews.indices {
            subviews[i].place(
                at: CGPoint(x: bounds.minX + xs[i], y: bounds.minY + CGFloat(lines[i]) * pitch - shift),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }
}

struct TokenView: View {
    let target: String
    let typed: String
    let caret: Int?
    let ghost: Int?
    let size: Double

    var body: some View {
        Text(styled)
            .font(.system(size: size, weight: .medium, design: .monospaced))
            .fixedSize()
    }

    private var styled: AttributedString {
        var out = AttributedString()
        let t = Array(target)
        let y = Array(typed)
        for (i, ch) in t.enumerated() {
            var a = AttributedString(String(ch))
            if i < y.count {
                if y[i] == ch {
                    a.foregroundColor = Color.primary
                } else {
                    a.foregroundColor = Color(nsColor: .systemRed)
                    a.backgroundColor = Color(nsColor: .systemRed).opacity(0.18)
                    a.underlineStyle = .single
                }
            } else {
                a.foregroundColor = Color.secondary
            }
            if caret == i {
                a.backgroundColor = Color.accentColor.opacity(0.35)
            } else if ghost == i {
                a.underlineStyle = Text.LineStyle(pattern: .solid, color: Color.accentColor)
            }
            out.append(a)
        }
        return out
    }
}
