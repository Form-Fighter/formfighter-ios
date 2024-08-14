import SwiftUI

struct MessageCell: View {
    var contentMessage: String
    var isCurrentUser: Bool
    
    var body: some View {
        Text(contentMessage)
            .padding(10)
            .foregroundStyle(isCurrentUser ? .customBackground : Color.primary)
            .background(isCurrentUser ? Color.brand : Color.bone)
            .cornerRadius(10)
            .fontDesign(.rounded)
    }
}

#Preview {
    MessageCell(contentMessage: "This is a single message cell.", isCurrentUser: false)
}
