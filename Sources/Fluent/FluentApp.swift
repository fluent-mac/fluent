import SwiftUI
import AppKit

@main
struct FluentApp: App {
    @StateObject private var store: Store
    @StateObject private var model: AppModel
    @AppStorage("menuBarExtra") private var menuBarExtra = false

    init() {
        let store = Store()
        _store = StateObject(wrappedValue: store)
        _model = StateObject(wrappedValue: AppModel(store: store))
    }

    var body: some Scene {
        Window("Fluent", id: "main") {
            RootView()
                .environmentObject(model)
                .environmentObject(store)
                .task { NSApplication.shared.activate() }
        }
        .defaultSize(width: 1040, height: 700)
        .commands {
            FluentCommands(model: model)
            SidebarCommands()
            ToolbarCommands()
        }

        Window("Fluent Help", id: "help") {
            HelpView()
        }
        .defaultSize(width: 560, height: 560)
        .defaultLaunchBehavior(.suppressed)

        MenuBarExtra("Fluent", systemImage: "keyboard", isInserted: $menuBarExtra) {
            MenuBarContent()
                .environmentObject(model)
        }

        Settings {
            SettingsView()
                .environmentObject(model)
                .environmentObject(store)
        }
    }
}
