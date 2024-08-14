import Foundation

class AuthBackendService {
    // MARK: - Backend Authentication. It is needed to do this once from our app.
    // We need to authenticate with our backend fetching a secret token, storing it in the Keychain.
    // It is necessary to do this once in the lifetime of the app.
    
    func fetchValue() async -> String {
        let result = await ApiClient.shared.sendRequest(endpoint: Endpoints.auth, responseModel: AuthBackendModel.self)
        
        switch result {
            case .success(let success):
                return success.value
            case .failure(let failure):
                Logger.log(message: failure.localizedDescription, event: .error)
                return ""
        }
    }
}
