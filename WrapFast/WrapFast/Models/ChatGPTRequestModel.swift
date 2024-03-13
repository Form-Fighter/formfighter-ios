import Foundation

// The model we send to our backend in order to make a request to ChatGPT API
struct ChatGPTRequestModel: Codable {
    let prompt: String
}
