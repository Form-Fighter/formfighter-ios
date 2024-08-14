import Foundation

// The model we send to our backend in order to make a request to DALLE API
struct DALLERequestModel: Encodable {
    let prompt: String
}
