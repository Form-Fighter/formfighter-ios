import SwiftUI

struct CustomSignInWithAppleButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "applelogo")
                    .font(.system(size: 24))
                Text("Sign in with Apple")
                    .font(.system(size: 24))
                    .fontWeight(.medium)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .background(colorScheme == .light ? .black : .white)
            .cornerRadius(10)
        }
    }
}

#Preview {
    CustomSignInWithAppleButton(action: {})
}
