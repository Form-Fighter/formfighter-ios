import SwiftUI

struct ChallengeHeaderView: View {
    let challenge: Challenge
    
    private var timeRemaining: String {
        let interval = challenge.endTime.timeIntervalSince(Date())
        guard interval > 0 else { return "Challenge ended" }
        
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m remaining"
        }
        return "\(minutes / 60)h \(minutes % 60)m remaining"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(challenge.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(challenge.description)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(ThemeColors.primary)
                Text(timeRemaining)
                    .foregroundColor(ThemeColors.primary)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
} 