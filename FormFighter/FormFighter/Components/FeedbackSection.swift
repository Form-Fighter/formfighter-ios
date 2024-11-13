import SwiftUI

struct FeedbackSection: View {
    let title: String
    let feedback: FeedbackModels.FeedbackDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(feedback.feedback)
                .foregroundColor(.secondary)
            Text("Score: \(String(format: "%.1f", feedback.score))")
                .font(.subheadline)
                .foregroundColor(.blue)
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
