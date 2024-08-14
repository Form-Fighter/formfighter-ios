import SwiftUI

struct OnboardingFeature: View {
    @State var image: Image
    @State var imageColor: Color = .black
    @State var title: LocalizedStringKey
    @State var description: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 16) {
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 36)
                .foregroundStyle(imageColor)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.special(.title3, weight: .bold))
                    .lineLimit(2)
                Text(description)
                    .font(.special(.body, weight: .regular))
            }
        }
    }
}

#Preview {
    OnboardingFeature(image: Image(systemName: "heart"), title: "Title", description: "Description")
}
