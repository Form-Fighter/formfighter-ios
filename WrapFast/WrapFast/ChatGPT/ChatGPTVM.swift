import Foundation

class ChatGPTVM: ObservableObject {
    @Published var messages = [Message]()
    @Published var newMessage: String = ""
    @Published var isRequesting = false
    let chatgptService: ChatGPTService
    
    init(chatgptService: ChatGPTService = ChatGPTService()) {
        self.chatgptService = chatgptService
        appendWelcomeMessage()
    }
    
    func appendWelcomeMessage() {
        messages.append(.init(id: UUID(), content: "Hi, I will be your assistant. Please make your requests.".localized, isCurrentUser: false))
    }
    
    @MainActor
    func sendMessage() {
        if !newMessage.isEmpty{
            messages.append(Message(content: newMessage, isCurrentUser: true))
            Logger.log(message: "Requesting ChatGPT message", event: .debug)
            sendChatgptPrompt(message: newMessage)
            newMessage = ""
        }
    }
    
    @MainActor
    func sendChatgptPrompt(message: String) {
        isRequesting = true
        Task {
            do {
                let response = try await chatgptService.sendPrompt(with: .init(prompt: message))
                isRequesting = false
                messages.append(Message(content: response.message, isCurrentUser: false))
            } catch {
                isRequesting = false
                Logger.log(message: error.localizedDescription, event: .error)
            }
        }
    }
}
