import Foundation

enum GPTLanguage: String, CaseIterable {
    // MARK: - These are the languages in which GPT can answer. The user will choose it.
    // Add or remove as many languages as you need
    
    case english
    case spanish
    case german
    case japanese
    case mandarin
    case galician
    case portuguese
    case arabic
    case korean
    case russian
    case hindi
    case euskera
    case catalan
    case french
    case italian
    
    var emoji: String {
        switch self {
            case .english:
                "🇺🇸"
            case .spanish:
                "🇪🇸"
            case .german:
                "🇩🇪"
            case .japanese:
                "🇯🇵"
            case .mandarin:
                "🇨🇳"
            case .italian:
                "🇮🇹"
            case .portuguese:
                "🇵🇹"
            case .arabic:
                "🇸🇦"
            case .korean:
                "🇰🇷"
            case .russian:
                "🇷🇺"
            case .hindi:
                "🇮🇳"
            case .french:
                "🇫🇷"
            case .galician:
                "🐙"
            case .euskera:
                "💚"
            case .catalan:
                "💛"
        }
    }
    
    var displayName: String {
        emoji + " " + self.rawValue.capitalized
    }
}
