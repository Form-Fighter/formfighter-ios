import Foundation

// The model that our backend send back to the app when we request a prompt to ChatGPT
struct ChatGPTResponse: Decodable {
    let message: String
}
