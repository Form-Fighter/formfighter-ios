import Foundation
import SwiftUI

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

struct ThemeColors {
    static let primary = Color("ThaiRed") // Deep red: #C41E3A
    static let secondary = Color("ThaiGold") // Gold: #FFD700
    static let accent = Color("ThaiBlack") // Deep black: #1A1A1A
    static let background = Color("ThaiGray") // Warm gray: #F5F5F5
}
