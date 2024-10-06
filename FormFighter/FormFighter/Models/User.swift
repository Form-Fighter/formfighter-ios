import Foundation

// MARK: Add more properties the User model regarding your needs
struct User: Codable {
    let id: String
    var name: String
    var firstName: String
    var lastName: String
    var weight: String
    var height: String
    var wingSpan: String
    var preferredStance: String
    let email: String
}

extension User {
    static func mockUser() -> User {
        User(id: UUID().uuidString, name: "Unknown", firstName:"Unknown", lastName: "Unknown", weight: "0", height: "0", wingSpan: "0", preferredStance: "Orthodox", email: "unknown@email.com")
    }
}
