import SwiftUI

struct PremiumBadgeView: View {
    var body: some View {
        Image(systemName: "crown.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.yellow)
            .padding(8)
            .background(.customBackground)
            .cornerRadius(12)
    }
}

#Preview {
    PremiumBadgeView()
}
