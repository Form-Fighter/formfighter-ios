import SwiftUI

struct ActiveChallengeView: View {
    let challenge: Challenge
    @State private var showShareSheet = false
    @StateObject private var viewModel = ChallengeViewModel()
    
    private var timeRemaining: String {
        let interval = challenge.endTime.timeIntervalSince(Date())
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m remaining"
        }
        return "\(minutes / 60)h \(minutes % 60)m remaining"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(challenge.description)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                        Text(timeRemaining)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(ThemeColors.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Share Button
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Challenge")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Leaderboard
                LeaderboardView(participants: challenge.participants)
                    .padding(.vertical)
                
                // Event Feed
                EventFeedView(events: challenge.events)
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL = viewModel.shareChallenge() {
                ShareSheet(items: [shareURL])
            }
        }
    }
}

// Preview Provider
struct ActiveChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        let challenge = Challenge(
            id: "preview",
            name: "Preview Challenge",
            description: "Test challenge",
            creatorId: "user1",
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200),
            participants: [],
            events: []
        )
        ActiveChallengeView(challenge: challenge)
    }
} 