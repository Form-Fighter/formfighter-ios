import Foundation

class DALLEVM: ObservableObject {
    @Published var messages = [Message]()
    @Published var pictures = [URL]()
    @Published var newMessage: String = ""
    @Published var isRequesting = false
    let dalleService: DALLEProtocol
    
    
    // By default, we instantiate the backend Service.
    // If you want to use AI Proxy, override this and inject the DALLEAIProxyService (they conform to the same DALLEProtocol)
    init(dalleService: DALLEProtocol = DALLEService()) {
        self.dalleService = dalleService
        appendWelcomeMessage()
    }
    
    func appendWelcomeMessage() {
        messages.append(.init(id: UUID(), content: "Hi, type your image generation requests.".localized, isCurrentUser: false))
    }
    
    @MainActor
    func sendMessage() {
        if !newMessage.isEmpty{
            messages.append(Message(content: newMessage, isCurrentUser: true))
            Logger.log(message: "Requesting image generation to DALLE message", event: .debug)
            sendDallePrompt(message: newMessage)
            newMessage = ""
        }
    }
    
    @MainActor
    func sendDallePrompt(message: String) {
        isRequesting = true
        Task {
            do {
                let response = try await dalleService.sendPrompt(with: .init(prompt: message))
                Logger.log(message: "Image received from DALLE: \(response.imageUrl.absoluteString)", event: .debug)
                isRequesting = false
                messages.append(Message(content: "", isCurrentUser: false, imageUrl: response.imageUrl))
            } catch {
                isRequesting = false
                Logger.log(message: error.localizedDescription, event: .error)
            }
        }
    }
}
