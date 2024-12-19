import SwiftUI

struct EventFeedView: View {
    let events: [Challenge.ChallengeEvent]
    
    private var groupedEvents: [(String, [Challenge.ChallengeEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events.sorted(by: { $0.timestamp > $1.timestamp })) { event in
            let components = calendar.dateComponents([.minute], from: event.timestamp, to: Date())
            if let minutes = components.minute {
                if minutes < 1 { return "Just now" }
                if minutes < 60 { return "\(minutes)m ago" }
                let hours = minutes / 60
                if hours < 24 { return "\(hours)h ago" }
                return calendar.startOfDay(for: event.timestamp).formatted(date: .abbreviated, time: .omitted)
            }
            return "Unknown"
        }
        return grouped.sorted { group1, group2 in
            let time1 = group1.value.first?.timestamp ?? Date()
            let time2 = group2.value.first?.timestamp ?? Date()
            return time1 > time2
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Feed")
                .font(.headline)
                .padding(.bottom, 4)
            
            if events.isEmpty {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(groupedEvents, id: \.0) { timeGroup, events in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(timeGroup)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                        
                        ForEach(events) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }
        }
    }
}

private struct EventRow: View {
    let event: Challenge.ChallengeEvent
    
    private var icon: String {
        switch event.type {
        case .invite: return "person.2.fill"
        case .score: return "star.fill"
        }
    }
    
    private var iconColor: Color {
        switch event.type {
        case .invite: return .blue
        case .score: return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.userName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(event.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
} 