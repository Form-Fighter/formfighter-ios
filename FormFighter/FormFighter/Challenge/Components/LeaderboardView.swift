import SwiftUI

struct LeaderboardView: View {
    let participants: [Challenge.Participant]
    
    private var sortedParticipants: [Challenge.Participant] {
        participants.sorted { $0.finalScore > $1.finalScore }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leaderboard")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                HStack(spacing: 12) {
                    // Rank & Medal
                    ZStack {
                        Circle()
                            .fill(index < 3 ? ThemeColors.primary.opacity(0.1) : Color.clear)
                            .frame(width: 36, height: 36)
                        
                        if index < 3 {
                            Image(systemName: ["trophy.fill", "medal.fill", "medal.fill"][index])
                                .foregroundColor([Color.yellow, Color.gray, Color.brown][index])
                        } else {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(participant.name)
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            StatView(icon: "person.2.fill", value: "\(participant.inviteCount)")
                            StatView(icon: "figure.boxing", value: "\(participant.totalJabs)")
                            StatView(icon: "star.fill", value: String(format: "%.1f", participant.averageScore))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.0f", participant.finalScore))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeColors.primary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
}

private struct StatView: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
        }
    }
}