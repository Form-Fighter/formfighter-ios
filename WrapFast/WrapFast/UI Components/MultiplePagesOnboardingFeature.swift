import SwiftUI

struct MultiplePagesOnboardingFeature: View {
    @State var model: MultiplePagesOnboardingFeatureModel
    
    var body: some View {
        VStack {
            Image(model.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
                .padding(.bottom)
            
            Text(model.title.localized)
                .font(.special(.title2, weight: .bold))
            Text(model.description.localized)
                .font(.special(.body, weight: .regular))
        }
    }
}

#Preview {
    MultiplePagesOnboardingFeature(model: .dummy)
}
