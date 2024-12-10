enum TabIdentifier: String {
    case vision = "vision"
    case profile = "profile"
    case challenge = "challenge"
    case settings = "settings"
} 


import SwiftUI

private struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<TabIdentifier> = .constant(.vision)
}

extension EnvironmentValues {
    var tabSelection: Binding<TabIdentifier> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}