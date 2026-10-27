import SwiftUI
import AppKit

struct WelcomeView: View {
    let done: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var iconIn = false
    @State private var titleIn = false
    @State private var hintIn = false
    @State private var glow = false

    var body: some View {
        Button(action: done) {
            ZStack {
                Rectangle().fill(.background)
                RadialGradient(colors: [Color.blue.opacity(glow ? 0.28 : 0.1), .clear], center: .center, startRadius: 20, endRadius: 420)
                    .ignoresSafeArea()
                VStack(spacing: 22) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                        .resizable()
                        .frame(width: 168, height: 168)
                        .scaleEffect(iconIn ? 1 : 0.5)
                        .rotationEffect(.degrees(iconIn ? 0 : -14))
                        .opacity(iconIn ? 1 : 0)
                        .shadow(color: .blue.opacity(0.35), radius: glow ? 40 : 12, y: 12)
                        .accessibilityHidden(true)
                    Text("Welcome to Fluent")
                        .font(.system(size: 44, weight: .bold))
                        .opacity(titleIn ? 1 : 0)
                        .offset(y: titleIn ? 0 : 14)
                    Text("Click anywhere to begin")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .opacity(hintIn ? 1 : 0)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
        .accessibilityLabel("Welcome to Fluent. Continue")
        .onAppear {
            if reduceMotion {
                iconIn = true; titleIn = true; hintIn = true
                return
            }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.6)) { iconIn = true }
            withAnimation(.easeOut(duration: 0.7).delay(0.5)) { titleIn = true }
            withAnimation(.easeOut(duration: 0.6).delay(1.1)) { hintIn = true }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}
