import Foundation

struct EmptyResponse: Codable {
    let status: Int
    
    init(status: Int) {
        self.status = status
    }
}
