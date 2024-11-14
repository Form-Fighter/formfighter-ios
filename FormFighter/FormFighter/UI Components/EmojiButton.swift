import SwiftUI
struct EmojiButton: View {
    let emoji: UserFeedbackType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(emoji.rawValue)
                    .font(.system(size: 50))
                Text(emoji.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.red.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
} 
