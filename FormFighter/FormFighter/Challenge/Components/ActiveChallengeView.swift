import SwiftUI
import FirebaseAuth

struct ActiveChallengeView: View {
    let challenge: Challenge
    @Environment(\.tabSelection) private var tabSelection
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Challenge Header with Countdown
                VStack(spacing: 8) {
                    Text(challenge.name)
                        .font(.title)
                    
                    Text(timeString(from: timeRemaining))
                        .font(.headline)
                        .foregroundColor(timeRemaining < 300 ? .red : ThemeColors.primary) // Red when < 5 minutes
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: { tabSelection.wrappedValue = .vision }) {
                        Label("Train", systemImage: "figure.boxing")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    ShareLink(item: "https://www.form-fighter.com/joinchallenge?challenge=\(challenge.id)&referrer=\(Auth.auth().currentUser?.uid ?? "")") {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                if !challenge.participants.isEmpty {
                    ParticipantsListView(participants: challenge.participants)
                }
                
                EventFeedView(events: challenge.recentEvents)
                    .padding(.top)
            }
            .padding()
        }
        .onAppear {
            updateTimeRemaining()
        }
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = challenge.endTime.timeIntervalSinceNow
        if timeRemaining <= 0 {
            // Challenge has ended
            timer.upstream.connect().cancel()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Challenge Ended"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "%02d:%02d:%02d remaining", hours, minutes, seconds)
    }
}

// Preview Provider
//struct ActiveChallengeView_Previews: PreviewProvider {
//    static var previews: some View {
//        let challenge = Challenge(
//            id: "preview",
//            name: "Preview Challenge",
//            description: "Test challenge",
//            creatorId: "user1",
//            startTime: Date(),
//            endTime: Date().addingTimeInterval(7200),
//            participants: []
//        )
//        ActiveChallengeView(challenge: challenge)
//    }
//} 

struct EventRowView: View {
    let event: Challenge.ChallengeEvent
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.userName)
                    .font(.headline)
                Text(event.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeFormatter.string(from: event.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ParticipantsListView: View {
    let participants: [Challenge.Participant]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Participants")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(participants.sorted { $0.finalScore > $1.finalScore }) { participant in
                ParticipantRowView(participant: participant)
                    .padding(.vertical, 4)
            }
        }
    }
}

struct ParticipantRowView: View {
    let participant: Challenge.Participant
    
    private var scoreMultiplier: Double {
        min(max(participant.averageScore / 10.0, 0.1), 2.0)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(participant.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 16) {
                    Label {
                        Text("\(participant.inviteCount)")
                            .frame(minWidth: 20)
                    } icon: {
                        Image(systemName: "person.2.fill")
                    }
                    .help("Invites: \(participant.inviteCount) × 25 points")
                    
                    Label {
                        Text("\(participant.totalJabs)")
                            .frame(minWidth: 20)
                    } icon: {
                        Image(systemName: "figure.boxing")
                    }
                    .help("Jabs: \(participant.totalJabs) × 0.2 points")
                    
                    Label {
                        Text(String(format: "%.1f", participant.averageScore))
                            .frame(minWidth: 30)
                    } icon: {
                        Image(systemName: "star.fill")
                    }
                    .help("Score multiplier: \(String(format: "%.1fx", scoreMultiplier))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "%.0f", participant.finalScore))
                    .font(.headline)
                    .foregroundColor(ThemeColors.primary)
                Text("points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct NoChallengeView: View {
    @Binding var showCreateChallenge: Bool
    @State private var showChallengeHistory = false
    @ObservedObject var viewModel: ChallengeViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.boxing")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.primary)
            
            Text("No Active Challenge")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create a challenge and invite friends to compete!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button {
                    showCreateChallenge = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Challenge")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button {
                    showChallengeHistory = true
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View Challenge History")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(ThemeColors.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ThemeColors.primary, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showChallengeHistory) {
            ChallengeHistoryView(challenges: viewModel.completedChallenges)
        }
    }
}


