import SwiftUI
import FirebaseAuth

struct ActiveChallengeView: View {
    let challenge: Challenge
    let viewModel: ChallengeViewModel
    
    init(challenge: Challenge, viewModel: ChallengeViewModel) {
        print("DEBUG: Initializing ActiveChallengeView")
        print("DEBUG: Challenge name: \(challenge.name)")
        self.challenge = challenge
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(challenge.name)
                    .font(.title)
                
                if !challenge.participants.isEmpty {
                    ParticipantsListView(participants: challenge.participants)
                }
                
                if !challenge.recentEvents.isEmpty {
                    LazyVStack {
                        ForEach(challenge.recentEvents) { event in
                            EventRowView(event: event)
                        }
                    }
                } else {
                    Text("No events yet")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
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
            
            Text(event.timestamp, style: .relative)
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
            }
        }
    }
}

struct ParticipantRowView: View {
    let participant: Challenge.Participant
    
    var body: some View {
        HStack {
            Text(participant.name)
            Spacer()
            VStack(alignment: .trailing) {
                Text("Score: \(Int(participant.finalScore))")
                Text("\(participant.totalJabs) jabs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NoChallengeView: View {
    @Binding var showCreateChallenge: Bool
    
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
            .padding(.horizontal)
        }
        .padding()
    }
}
