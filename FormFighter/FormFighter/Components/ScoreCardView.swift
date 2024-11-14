import SwiftUI

struct ScoreCardView: View {
    let jabScore: Double
    
    var body: some View {
        VStack {
            Text("Jab Score")
                .font(.headline)
            Text(String(format: "%.1f", jabScore))
                .font(.largeTitle)
                .foregroundColor(ThemeColors.primary)
        }
        .padding()
        .background(ThemeColors.primary.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ScoreCardView(jabScore: 8.5)
} 