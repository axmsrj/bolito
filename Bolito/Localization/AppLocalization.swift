import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case portugueseBrazil = "pt-BR"

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .system: "language.system"
        case .english: "language.english"
        case .portugueseBrazil: "language.portuguese"
        }
    }

    var locale: Locale {
        Locale(identifier: localizationIdentifier)
    }

    fileprivate var localizationIdentifier: String {
        switch self {
        case .english:
            "en"
        case .portugueseBrazil:
            "pt-BR"
        case .system:
            Locale.preferredLanguages.first?.hasPrefix("pt") == true ? "pt-BR" : "en"
        }
    }
}

struct AppLocalizer {
    let language: AppLanguage

    var locale: Locale {
        language.locale
    }

    func string(_ key: String) -> String {
        let identifier = language.localizationIdentifier

        guard let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main.localizedString(forKey: key, value: key, table: nil)
        }

        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
