import Foundation
import FirebaseFirestore

struct Challenge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let creatorId: String
    let startTime: Date
    let endTime: Date
    
    // These will be populated from subcollections
    var participants: [Participant] = []
    var recentEvents: [ChallengeEvent] = []
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, creatorId, startTime, endTime
    }
    
    // Custom init to handle Firestore decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        participants = []
        recentEvents = []
    }
    
    // Regular init for creating new challenges
    init(id: String, name: String, description: String, creatorId: String, startTime: Date, endTime: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.creatorId = creatorId
        self.startTime = startTime
        self.endTime = endTime
        self.participants = []
        self.recentEvents = []
    }
    
    struct Participant: Codable, Identifiable {
        let id: String
        let name: String
        var inviteCount: Int
        var totalJabs: Int
        var averageScore: Double
        var finalScore: Double {
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