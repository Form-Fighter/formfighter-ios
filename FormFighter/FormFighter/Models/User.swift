import Foundation

struct User: Codable {
    let id: String
    var name: String
    var firstName: String
    var lastName: String
    var coachID: String
    var myCoach: String
    var height: String?
    var weight: String?
    var wingspan: String?
    var preferredStance: String?
    let email: String
    var currentStreak: Int?
    var lastTrainingDate: Date?
}

extension User {
    static func mockUser() -> User {
        User(id: UUID().uuidString, 
             name: "Unknown", 
             firstName: "Unknown", 
             lastName: "Unknown", 
             coachID: "Unknown", 
             myCoach: "Unknown",
             height: "",
             weight: "",
             wingspan: "",
             preferredStance: "",
             email: "unknown@email.com",
             currentStreak: 0,
             lastTrainingDate: nil)
    }
}
