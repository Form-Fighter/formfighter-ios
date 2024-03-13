import Foundation

enum DALLEError: Error {
    case sendPromptError
    
    var localizedDescription: String {
        switch self {
        case .sendPromptError:
            "Error requesting prompt"
        }
    }
}

// This is a example of how you can send to DALLE API prompts to request images.
// You can tweak the request models depending on your needs and handle them in the backend to
// build proper prompts or handle custom logic.
class DALLEService {
    func sendPrompt(with model: DALLERequestModel) async throws -> DALLEResponse {
        let result = try await ApiClient.shared.sendRequest(
            endpoint: Endpoints.dalle,
            body: JSONEncoder().encode(model),
            responseModel: DALLEResponse.self
        )
        
        switch result {
        case .success(let dalleResponse):
            return dalleResponse
        case .failure(let failure):
            Logger.log(message: failure.localizedDescription, event: .error)
            throw DALLEError.sendPromptError
        }
    }
}
