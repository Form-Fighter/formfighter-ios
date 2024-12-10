import Foundation

struct Badge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let type: BadgeType
    let iconName: String // SF Symbol name
    let targetValue: Int? // For progress/cumulative badges
    
    // Category for future filtering/sorting
    let category: BadgeCategory
}

enum BadgeType: String, Codable {
    case instant
    case progress
    case cumulative
}

enum BadgeCategory: String, Codable {
    case streak
    case performance
    case volume
    case improvement
    case challenge
    case engagement
    case milestone
    case fun
    case community
}

struct BadgeProgress: Codable {
    let badgeId: String
    let currentValue: Int
    let targetValue: Int
    let progressStartDate: Date
    
    var percentageComplete: Double {
        Double(currentValue) / Double(targetValue)
    }
}

// For Firestore
struct UserBadge: Codable {
    let badgeId: String
    let earnedAt: Date
    let count: Int
} 
