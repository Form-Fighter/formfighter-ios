import Foundation
import FirebaseFirestore

struct Challenge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let creatorId: String
    let startTime: Date
    let endTime: Date
    var participants: [Participant]
    var events: [ChallengeEvent]
    
    struct Participant: Codable, Identifiable {
        let id: String
        let name: String
        var inviteCount: Int
        var totalJabs: Int
        var averageScore: Double
        var finalScore: Double {
            // Clout (0.5) + Volume (0.2) × Technique multiplier (0-2.0)
            let baseScore = (Double(inviteCount) * 50.0 * 0.5) + (Double(totalJabs) * 0.2)
            let multiplier = min(max(averageScore / 10.0, 0.1), 2.0)
            return baseScore * multiplier
        }
    }
    
    struct ChallengeEvent: Codable, Identifiable {
        let id: String
        let timestamp: Date
        let type: EventType
        let userId: String
        let userName: String
        var details: String
        
        enum EventType: String, Codable {
            case invite
            case score
            case volume
        }
    }
} 