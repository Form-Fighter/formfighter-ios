import SwiftUI

struct FeedbackSection: View {
    let title: String
    let feedback: FeedbackModels.FeedbackDetails
    
    private var sectionIcon: String {
        switch title {
        case "Extension":
            return "arrow.up.forward" // Represents extending/reaching out
        case "Guard":
            return "shield.fill" // Represents defense/protection
        case "Retraction":
            return "arrow.down.backward" // Represents pulling back
        default:
            return "figure.martial.arts"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: sectionIcon)
                    .font(.title2)
                    .foregroundColor(.red)
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
            Text(feedback.feedback)
                .foregroundColor(.secondary)
            Text("Score: \(String(format: "%.1f", feedback.score))")
                .font(.subheadline)
                .foregroundColor(ThemeColors.primary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    FeedbackSection(
        title: "Extension",
        feedback: FeedbackModels.FeedbackDetails(
            feedback: "Good extension on your jab",
            score: 8.5
        )
    )
} 
