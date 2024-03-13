import SwiftUI

struct PillButton: View {
    @State var title: LocalizedStringKey
    @State var color: Color
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.special(.body, weight: .semibold))
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 44)
        }
        .tint(color)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
    }
}

#Preview {
    PillButton(title: "Continue", color: .brand, action: {})
}
