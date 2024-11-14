import SwiftUI
import Firebase

enum UserFeedbackType: String, CaseIterable, Hashable {
    case happy = "😊"
    case okay = "😐"
    case sad = "☹️"
    
var description: String {
        switch self {
        case .happy:
            return "Amazing!"
        case .okay:
            return "It's Okay"
        case .sad:
            return "Needs Work"
        }
    }
    
}

struct UserFeedbackSheet: View {
    @Binding var userComment: String
    @Binding var selectedEmoji: UserFeedbackType?
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    private let emojis: [UserFeedbackType] = [.happy, .okay, .sad]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Emoji Selection
                HStack(spacing: 30) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji.rawValue)
                                .font(.system(size: 40))
                                .opacity(selectedEmoji == emoji ? 1 : 0.5)
                        }
                    }
                }
                
                // Comment Field
                TextEditor(text: $userComment)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .padding(.horizontal)
                
                Text("\(userComment.count)/500 characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Your Feedback")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Submit") {
                    onSubmit()
                }
                .disabled(userComment.count < 15 || selectedEmoji == nil)
            )
        }
    }
} 
