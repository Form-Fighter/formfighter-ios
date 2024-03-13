import Foundation

// MARK: Add more properties the User model regarding your needs
struct User: Codable {
    let id: String
    var name: String
    let email: String
}

extension User {
    static func mockUser() -> User {
        User(id: UUID().uuidString, name: "Unknown", email: "unknown@email.com")
    }
}
