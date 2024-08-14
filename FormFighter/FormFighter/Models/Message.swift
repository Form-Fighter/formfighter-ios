import Foundation

// The message model we use within the app
struct Message: Hashable {
    var id = UUID()
    var content: String
    var isCurrentUser: Bool
    var imageUrl: URL?
}
