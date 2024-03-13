import SwiftUI

struct DeleteConfirmationAlert: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    var onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Are you sure you want to delete the account?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            Text("Please type '\(Const.deleteUserWordConfirmation.uppercased())' to confirm.")
                .font(.subheadline)
            
            TextField("Type here", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    text = ""
                    isPresented = false
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
                
                Spacer()
                
                Button("Delete") {
                    if text.uppercased() == Const.deleteUserWordConfirmation.uppercased() {
                        onDelete()
                    } else {
                        Haptic.shared.notificationOccurred(type: .error)
                        text = ""
                    }
                    isPresented = false
                }
                .foregroundColor(.red)
                .fontWeight(.bold)
            }
            .padding(.horizontal, 32)
        }
        .padding()
        .background(.customBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }
}

#Preview {
    DeleteConfirmationAlert(text: .constant("Delete confirmation"), isPresented: .constant(true), onDelete: {})
}
