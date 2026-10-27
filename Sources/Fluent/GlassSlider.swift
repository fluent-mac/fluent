import SwiftUI

struct GlassSlider: View {
    let title: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        HStack(spacing: 14) {
            Text(title).font(.callout).foregroundStyle(.secondary)
            Slider(
                value: Binding(get: { Double(value) }, set: { value = Int($0) }),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            Text("\(value) \(unit)")
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: Capsule())
        .frame(maxWidth: 440)
        .accessibilityElement(children: .contain)
    }
}
