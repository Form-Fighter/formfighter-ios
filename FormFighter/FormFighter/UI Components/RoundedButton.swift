import SwiftUI

struct RoundedButton: View {
    @State var title: LocalizedStringKey
    @State var color: Color = .brand
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.special(.title3, weight: .semibold))
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 44)
        }
        .tint(color)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle)
    }
}

#Preview {
    RoundedButton(title: "Continue", color: .brand, action: {})
}
