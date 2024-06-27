import Foundation
import KeychainSwift

// This is an example of how can you use the API Client to make requests to endpoints.
// In this case we create the endpoints in our backend, but you can use it to make any http request
// to the endpoints you need, for example to other third party APIs.
enum Endpoints {
    case auth
    case vision
    case chatgpt
    case dalle
    case anthropicMessages
}

extension Endpoints: Endpoint {
    
    var baseURL: String {
        switch self {
        default:
            return Const.Api.baseURL
        }
    }
    
    var path: String {
        switch self {
        case .auth:
            return "auth"
        case .vision:
            return "vision"
        case .chatgpt:
            return "chatgpt"
        case .dalle:
            return "dalle"
        case .anthropicMessages:
            return "anthropic-messages"
        }
    }
    
    // Set custom headers in the http request, depending which Endpoint we use.
    // For the auth endpoint we sign the endpoint path with the secret key, creating a HMAC key
    // that the backend should check. If the check is ok, the backend answer with a secret key that we store in the Keychain.
    var header: [String : String]? {
        switch self {
        case .auth:
            return [
                "X-Signature": "\(CryptoUtils.shared.createHmac(key: Const.Api.authKey, phrase: "/" + path))"
            ]
            
            // To make requests to our backend endpoints, we fetch the auth secret key stored in the keychain and send it
            // within a X-Signature header.
            // We also send our app identifier to allow handle custom login within the backend depending on which app
            // make the request.
        case .vision, .chatgpt, .dalle, .anthropicMessages:
            let keychain = KeychainSwift()
            let signature = CryptoUtils.shared.createHmac(key: keychain.get(Const.Keychain.tokenKey) ?? "", phrase: "/" + path)
            return [
                "X-Signature": "\(signature)",
                "X-App-Identifier": "\(Const.Api.appIdentifier)"
            ]
        }
    }
    
    // Use this if you need to send some payload data in the request body
    var body: [String : String]? {
        nil
    }
    
    // Specify which http method use each endpoint.
    var method: RequestMethod {
        switch self {
        case .vision, .chatgpt, .dalle, .anthropicMessages:
            return .post
        case .auth:
            return.get
        }
    }
}
