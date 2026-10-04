import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    private var localizer: AppLocalizer {
        AppLocalizer(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }

    var body: some View {
        Form {
            Picker(localizer.string("settings.language"), selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(verbatim: localizer.string(language.titleKey))
                        .tag(language.rawValue)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 220)
    }
}
