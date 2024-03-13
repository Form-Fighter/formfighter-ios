import SwiftUI

extension View {
    @ViewBuilder
    func `if`<TrueContent: View>(_ condition: Bool, transform: (Self) -> TrueContent) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
