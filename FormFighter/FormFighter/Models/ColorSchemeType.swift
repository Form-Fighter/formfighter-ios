import Foundation

enum ColorSchemeType: Int, Identifiable, CaseIterable {
    var id: Self { self }
    case system
    case light
    case dark
}

extension ColorSchemeType {
    var title: String {
        switch self {
        case .system:
            "📱 System"
        case .light:
            "☀️ Light"
        case .dark:
            "🌙 Dark"
        }
    }
}
