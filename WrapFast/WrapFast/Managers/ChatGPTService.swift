import Foundation

enum ChatGPTError: Error {
    case sendPromptError
    
    var localizedDescription: String {
        switch self {
        case .sendPromptError:
            "Error requesting prompt"
        }
    }
}

// This is a example of how you can send to ChatGPT API prompts.
// You can tweak the request models depending on your needs and handle them in the backend to
// build proper prompts or handle custom logic.
class ChatGPTService {
    func sendPrompt(with model: ChatGPTRequestModel) async throws -> ChatGPTResponse {
        let result = try await ApiClient.shared.sendRequest(
            endpoint: Endpoints.chatgpt,
            body: JSONEncoder().encode(model),
            responseModel: ChatGPTResponse.self
        )
        
        switch result {
        case .success(let chatgptResponse):
            return chatgptResponse
        case .failure(let failure):
            Logger.log(message: failure.localizedDescription, event: .error)
            throw ChatGPTError.sendPromptError
        }
    }
}
