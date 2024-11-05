//import Foundation
//import AIProxy
//
//enum ChatGPTError: Error {
//    case sendPromptError
//    
//    var localizedDescription: String {
//        switch self {
//        case .sendPromptError:
//            "Error requesting prompt"
//        }
//    }
//}
//
//protocol ChatGPTProtocol {
//    func sendPrompt(with model: ChatGPTRequestModel) async throws -> ChatGPTResponse
//}
//
//// This is a example of how you can send to ChatGPT API prompts.
//// You can tweak the request models depending on your needs and handle them in the backend to
//// build proper prompts or handle custom logic.
//class ChatGPTService: ChatGPTProtocol {
//    func sendPrompt(with model: ChatGPTRequestModel) async throws -> ChatGPTResponse {
//        let result = try await ApiClient.shared.sendRequest(
//            endpoint: Endpoints.chatgpt, // Use Endpoints.anthropicMessages for using Anthropic
//            body: JSONEncoder().encode(model),
//            responseModel: ChatGPTResponse.self
//        )
//        
//        switch result {
//        case .success(let chatgptResponse):
//            return chatgptResponse
//        case .failure(let failure):
//            Logger.log(message: failure.localizedDescription, event: .error)
//            throw ChatGPTError.sendPromptError
//        }
//    }
//}
//
//// This is an example of how you can use AI Proxy to make requests to ChatGPT instead of using the Node AI Backend
//// Check AIProxy's integration guide for more info: https://www.aiproxy.pro/docs/integration-guide.html
//class ChatGPTAIProxyService: ChatGPTProtocol {
//    func sendPrompt(with model: ChatGPTRequestModel) async throws -> ChatGPTResponse {
//        let openAIService = AIProxy.openAIService(partialKey: Const.AIProxy.partialKey)
//        
//        // You can tweak from here parameters like the model to use, max tokens, how the system should be have etc...
//        // It's the same as we would do in the Node backend.
//        let response = try await openAIService.chatCompletionRequest(body: .init(
//            model: "gpt-4o",
//            messages: [
//                .init(role: "system", content: .text("You are a helpful assistant.")),
//                .init(role: "user", content: .text(model.prompt))
//            ]
//        ))
//        
//        if let text = response.choices.first?.message.content {
//            return ChatGPTResponse(message: text)
//        } else {
//            throw ChatGPTError.sendPromptError
//        }
//    }
//}
