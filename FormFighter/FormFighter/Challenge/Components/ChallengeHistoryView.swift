import SwiftUI

struct ChallengeHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let challenges: [Challenge]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(challenges.sorted(by: { $0.endTime > $1.endTime })) { challenge in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(challenge.name)
                            .font(.headline)
                        
                        Text(challenge.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label("\(challenge.participants.count)", systemImage: "person.2")
                            Spacer()
                            Text(challenge.endTime.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Challenge History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ChallengeHistoryCard: View {
    let challenge: Challenge
    
    private var winner: Challenge.Participant? {
        challenge.participants.max { $0.finalScore < $1.finalScore }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(challenge.name)
                        .font(.headline)
                    Text(challenge.endTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let winner = winner {
                    VStack(alignment: .trailing) {
                        Text("Winner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(winner.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 20) {
                StatView(title: "Participants", value: "\(challenge.participants.count)")
                StatView(title: "Total Jabs", value: "\(challenge.participants.reduce(0) { $0 + $1.totalJabs })")
                StatView(title: "Avg Score", value: String(format: "%.1f", challenge.participants.reduce(0.0) { $0 + $1.averageScore } / Double(challenge.participants.count)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

private struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
} 
