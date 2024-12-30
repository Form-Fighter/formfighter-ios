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
        let fcmToken: String?
        
        var finalScore: Double {
            // Base score from invites: each invite worth 25 points
            let inviteScore = Double(inviteCount) * 25.0
            
            // Base score from jabs: each jab worth 20 points (scaled up from 0.2)
            let jabScore = Double(totalJabs) * 20.0
            
            // Score multiplier based on average score (between 0.1x and 2.0x)
            let multiplier = min(max(averageScore / 10.0, 0.1), 2.0)
            
            // Final calculation
            let score = (inviteScore + jabScore) * multiplier
            
            // Round to nearest whole number
            return round(score)
        }
    }
    
    struct ChallengeEvent: Codable, Identifiable {
        let id: String
        let timestamp: Date
        let type: EventType
        let userId: String
        let userName: String
        let details: String
        let feedbackId: String?
        
        enum EventType: String, Codable {
            case invite
            case score
        }
    }
} 