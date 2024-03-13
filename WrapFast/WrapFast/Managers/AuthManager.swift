import Foundation
import FirebaseAuth
import AuthenticationServices
import Combine
import CryptoKit

enum SignInWithAppleError: Error {
    case credentialError
    case authenticationError(String)
}

enum AuthError: Error {
    case logoutError
    
    var localizedDescription: String {
        switch self {
            case .logoutError:
                "Error loging out"
        }
    }
}

struct SSOUser {
    let email: String
    let token: String
}

final class AuthManager: ObservableObject {
    private let signInWithAppleCoordinator = SignInWithAppleCoordinator()
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    func signInWithApple() async throws -> SSOUser {
        signInWithAppleCoordinator.signIn()
        
        return try await withCheckedThrowingContinuation { continuation in
            signInWithAppleCoordinator.ssoUser
                .first()
                .sink(receiveCompletion: { [weak self] completion in
                    self?.cancellables.removeAll()
                    switch completion {
                    case .failure(let error):
                        Logger.log(message: "Error signing in with Apple: \(error.localizedDescription)", event: .error)
                        continuation.resume(throwing: error)
                    case .finished:
                        Logger.log(message: "Sign in with Apple publisher finished", event: .debug)
                        break
                    }
                }, receiveValue: { ssoUser in
                    Logger.log(message: "Sign in with Apple publisher received SSOUser value.", event: .debug)
                    continuation.resume(with: .success(ssoUser))
                })
                .store(in: &cancellables)
        }
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(nil)
        } catch {
            Logger.log(message: "Error signing out in Firebase: \(error.localizedDescription)", event: .error)
            completion(AuthError.logoutError)
        }
    }
    
    func deleteUser(completion: @escaping (Error?) -> Void) {
        refreshUserAuthToken { result in
            switch result {
                case .success(_):
                    let user = Auth.auth().currentUser
                    user?.delete(completion: { error in
                        if let error = error {
                            Logger.log(message: "Error deleting authenticated user: \(error.localizedDescription)", event: .error)
                            completion(error)
                        } else {
                            Logger.log(message: "Authenticated user deleted successfully", event: .info)
                            completion(nil)
                        }
                    })
                    
                case .failure(let failure):
                    completion(failure)
            }
        }
        
    }
    
    func refreshUserAuthToken(completion: @escaping (Result<String, Error>) -> Void) {
        let user = Auth.auth().currentUser
        
        user?.getIDTokenForcingRefresh(true, completion: { token, error in
            if let error = error {
                Logger.log(message: error.localizedDescription, event: .error)
                completion(.failure(error))
            } else if let token = token {
                Logger.log(message: "Refreshed user auth, new token: \(token)", event: .debug)
                completion(.success(token))
            }
        })
    }
    
}

class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate {
    private var currentNonce: String?
    let ssoUser = PassthroughSubject<SSOUser, Error>()
    
    
    //Extracted from Firebase documentation
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            Logger.log(message: "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)", event: .error)
            return nil
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    //Extracted from Firebase documentation
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        guard let nonce = randomNonceString() else {
            Logger.log(message: "Nonce is nil", event: .debug)
            return
        }
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            guard let nonce = currentNonce else {
                Logger.log(message: "Unable create a nonce.", event: .debug)
                return
            }
            
            guard let appleIdToken = appleIDCredential.identityToken else {
                Logger.log(message: "Unable to fetch identity token", event: .debug)
                return
            }
            
            guard let appleIdTokenString = String(data: appleIdToken, encoding: .utf8) else {
                Logger.log(message: "Unable decode token string from data: \(appleIdToken.debugDescription)", event: .debug)
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: appleIdTokenString, rawNonce: nonce)
            
            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    Logger.log(message: "User authenticated in Firebase with Apple with email: \(result.user.email ?? "")", event: .info)
                    let tokenResult = try await result.user.getIDTokenResult()
                    Logger.log(message: "Access token for authenticated user: \(tokenResult.token)", event: .debug)
                    ssoUser.send(SSOUser(email: result.user.email ?? "unknown", token: tokenResult.token))
                }
                catch {
                    ssoUser.send(completion: .failure(SignInWithAppleError.authenticationError(error.localizedDescription)))
                    Logger.log(message: "Error authenticating: \(error.localizedDescription)", event: .error)
                }
            }
            
        } else {
            ssoUser.send(completion: .failure(SignInWithAppleError.credentialError))
            Logger.log(message: "Apple id credential is nil", event: .debug)
        }
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.log(message: "Error authenticating: \(error.localizedDescription)", event: .error)
        ssoUser.send(completion: .failure(SignInWithAppleError.authenticationError(error.localizedDescription)))
    }
}
