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
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id &&
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
        lhs.lastTrainingDate == rhs.lastTrainingDate
    }
}

extension User {
    static func mockUser() -> User {
        User(id: UUID().uuidString, 
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
             lastTrainingDate: nil)
    }
}
