import SwiftUI

struct PaywallFeature: View {
    @State var title: LocalizedStringKey
    @State var description: LocalizedStringKey
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.special(.title2, weight: .bold))
            Text(description)
                .font(.special(.body, weight: .regular))
        }
    }
}

#Preview {
    PaywallFeature(title: "Title", description: "Description")
}
