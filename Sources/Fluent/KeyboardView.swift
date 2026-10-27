import SwiftUI
import FluentCore

func clockString(_ s: Double) -> String {
    let t = Int(max(0, s).rounded(.up))
    return String(format: "%d:%02d", t / 60, t % 60)
}

func durationString(_ s: Double) -> String {
    let m = Int(s / 60)
    if m >= 60 { return "\(m / 60) h \(m % 60) min" }
    if m >= 1 { return "\(m) min" }
    return "\(Int(s)) s"
}

struct KeyboardView: View {
    let layout: KeyboardLayout
    var highlight: Character?
    var intensity: (Character) -> Double = { _ in 0 }
    var selection: Character?
    var onSelect: ((Character) -> Void)?
    var keySize: CGFloat = 38

    private let gap: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(Array(layout.rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: gap) {
                    ForEach(row, id: \.self) { ch in key(ch) }
                }
                .padding(.leading, KeyboardLayout.stagger[index] * (keySize + gap))
            }
            HStack(spacing: gap) {
                space
            }
            .padding(.leading, 2.5 * (keySize + gap))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(layout.title) keyboard")
    }

    private func key(_ ch: Character) -> some View {
        let isSel = selection == ch
        let isNext = highlight == ch
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.07))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(min(intensity(ch), 1) * 0.7))
            }
            .overlay {
                Text(String(ch).uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .overlay {
                if isSel || isNext {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .frame(width: keySize, height: keySize)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture { onSelect?(ch) }
    }

    private var space: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.07))
            .overlay {
                if highlight == " " {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .frame(width: keySize * 5 + gap * 4, height: keySize)
    }
}
