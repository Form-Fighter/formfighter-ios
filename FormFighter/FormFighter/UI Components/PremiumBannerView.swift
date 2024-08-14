import SwiftUI

struct PremiumBannerView: View {
    @State var color: Color = .brand
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(color.gradient)
                .frame(maxWidth: .infinity, maxHeight: 72)
            HStack {
                PremiumBadgeView()
                    .frame(height: 40)
                
                Text("Unlock Premium Features")
                    .font(.special(.title2, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .shadow(radius: 5, y: 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

#Preview {
    PremiumBannerView(color: .brand)
        .padding()
}
