import Foundation

struct User: Codable, Equatable {
    let id: String
    var name: String
    var firstName: String
    var lastName: String
    var coachId: String
    var myCoach: String
    var height: String?
    var weight: String?
    var reach: String?
    var preferredStance: String?
    let email: String
    var currentStreak: Int?
    var lastTrainingDate: Date?
    var stripeCustomerId: String?
    var membershipEndsAt: Date?
    var currentPeriodEnd: Date?
    var subscriptionId: String?
    var tokens: Int?
    var isFreeUser: Bool?
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.firstName == rhs.firstName &&
            lhs.lastName == rhs.lastName &&
            lhs.coachId == rhs.coachId &&
            lhs.myCoach == rhs.myCoach &&
            lhs.height == rhs.height &&
            lhs.weight == rhs.weight &&
            lhs.reach == rhs.reach &&
            lhs.preferredStance == rhs.preferredStance &&
            lhs.email == rhs.email &&
            lhs.currentStreak == rhs.currentStreak &&
            lhs.lastTrainingDate == rhs.lastTrainingDate &&
            lhs.membershipEndsAt == rhs.membershipEndsAt &&
            lhs.currentPeriodEnd == rhs.currentPeriodEnd &&
            lhs.subscriptionId == rhs.subscriptionId &&
            lhs.stripeCustomerId == rhs.stripeCustomerId &&
            lhs.tokens == rhs.tokens &&
            lhs.isFreeUser == rhs.isFreeUser
    }
}

extension User {
    static func mockUser() -> User {
        return User(
            id: UUID().uuidString,
            name: "Unknown",
            firstName: "Unknown",
            lastName: "Unknown",
            coachId: "Unknown",
            myCoach: "Unknown",
            height: "",
            weight: "",
            reach: "",
            preferredStance: "",
            email: "unknown@email.com",
            currentStreak: 0,
            lastTrainingDate: nil,
            stripeCustomerId: nil,
            membershipEndsAt: nil,
            currentPeriodEnd: nil,
            subscriptionId: nil,
            tokens: 0,
            isFreeUser: false
        )
    }
}
