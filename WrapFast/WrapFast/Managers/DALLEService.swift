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

protocol DALLEProtocol {
    func sendPrompt(with model: DALLERequestModel) async throws -> DALLEResponse
}

// This is a example of how you can send to DALLE API prompts to request images.
// You can tweak the request models depending on your needs and handle them in the backend to
// build proper prompts or handle custom logic.
class DALLEService: DALLEProtocol {
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

// This is an example of how you can use AI Proxy to make requests to DALLE instead of using the Node AI Backend
class DALLEAIProxyService: DALLEProtocol {
    func sendPrompt(with model: DALLERequestModel) async throws -> DALLEResponse {
        
        // You can tweak from here parameters like the prompt to use, image size, number of images generated etc...
        // It's the same as we would do in the Node backend.
        let requestBody = AIProxy.ImageGenerationRequestBody(
            prompt: model.prompt,
            size: "1024x1024",
            numberOfImages: 1
        )
        
        do {
            let response = try await AIProxy.imageGenerationRequest(imageRequestBody: requestBody)
            
            guard let imageUrl = response.data.first?.url else {
                throw DALLEError.sendPromptError
            }
            
            return DALLEResponse(imageUrl: imageUrl)
        } catch {
            throw DALLEError.sendPromptError
        }
    }
}
