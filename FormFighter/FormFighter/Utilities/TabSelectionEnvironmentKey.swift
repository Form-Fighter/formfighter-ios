import SwiftUI

struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<TabIdentifier> = .constant(.vision)
}

extension EnvironmentValues {
    var tabSelection: Binding<TabIdentifier> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
} 