import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @State private var columns = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            List(
                selection: Binding<AppSection?>(
                    get: { model.section },
                    set: { if let s = $0 { model.section = s } }
                )
            ) {
                Label(AppSection.home.title, systemImage: AppSection.home.symbol).tag(AppSection.home)
                ForEach(AppSection.groups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.items) { s in
                            Label(s.title, systemImage: s.symbol).tag(s)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 240)
        } detail: {
            switch model.section {
            case .home: HomeView()
            case .practice: PracticeView()
            case .progress: HistoryView()
            case .keys: KeysView()
            case .clicks: ClicksView()
            case .reaction: ReactionView()
            case .aim: AimView()
            case .mouse: MouseView()
            case .keyboard: KeyboardTestView()
            case .trackpad: TrackpadView()
            case .shortcuts: ShortcutsView()
            case .macCheck: MacCheckView()
            case .surface: SurfaceView()
            case .display: DisplayTestView()
            case .audio: AudioView()
            case .camera: CameraView()
            case .tweaks: TweaksView()
            }
        }
        .frame(minWidth: 900, minHeight: 540)
        .sheet(isPresented: $model.showCustomSheet) { CustomTextSheet() }
        .onChange(of: model.settingsRequest) { openSettings() }
        .onChange(of: model.helpRequest) { openWindow(id: "help") }
        .overlay {
            if model.showWelcome {
                WelcomeView {
                    UserDefaults.standard.set(true, forKey: "welcomed")
                    withAnimation(.easeInOut(duration: 0.5)) { model.showWelcome = false }
                }
                .transition(.opacity)
            }
        }
        .onAppear { model.applyFloating() }
    }
}
