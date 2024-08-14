import Foundation

enum RequestError: Error, Equatable {
    case decode
    case invalidURL
    case noResponse
    case unAuthorized(code: Int)
    case unexpectedStatusCode
    case noNetworkConnection
    case serverError(code: Int)
    case unknown
    
    var errorMessage: String {
        switch self {
        case .decode:
            return "Decode error"
        case .invalidURL:
            return "Invalid URL"
        case .noResponse:
            return "No Response"
        case .unAuthorized(let code):
            return "Authorization failure. Response code: \(code). Error: \(localizedDescription)"
        case .noNetworkConnection:
            return "There is no network connection"
        default:
            return "Unknown error"
        }
    }
}
