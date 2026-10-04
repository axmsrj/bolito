import SwiftUI
import SwiftData

@main struct MyApp: App {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    private var selectedLocale: Locale {
        AppLanguage(rawValue: appLanguage)?.locale ?? .autoupdatingCurrent
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
        }
        .defaultSize(width: 1260, height: 765)
        .modelContainer(for: [Board.self, Column.self, Task.self])
        .commands {
            BackupCommands()
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
        }
        #endif
    }
}
