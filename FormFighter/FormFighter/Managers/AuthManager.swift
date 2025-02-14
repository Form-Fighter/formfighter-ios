import Foundation
import FirebaseAuth
import AuthenticationServices
import Combine
import CryptoKit

enum SignInWithAppleError: LocalizedError {
    case credentialError
    case authenticationError(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .credentialError:
            return "Failed to get Apple ID credentials"
        case .authenticationError(let message):
            return "Authentication failed: \(message)"
        case .cancelled:
            return "Sign in was cancelled"
        }
    }
}

enum AuthError: Error {
    case logoutError
    case userNotFound
    
    var localizedDescription: String {
        switch self {
            case .logoutError:
                "Error loging out"
            case .userNotFound:
                "User not found"
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
        // Cancel any existing sign-in attempts first
        cancellables.removeAll()
        
        signInWithAppleCoordinator.signIn()
        
        return try await withCheckedThrowingContinuation { continuation in
            signInWithAppleCoordinator.ssoUser
                .first()  // This ensures we only take the first value
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
    
    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        
        // Refresh token first
        // try await withCheckedThrowingContinuation { continuation in
        //     refreshUserAuthToken { result in
        //         switch result {
        //         case .success(_):
        //             continuation.resume()
        //         case .failure(let error):
        //             continuation.resume(throwing: error)
        //         }
        //     }
        // }
        
        // Delete the user
        try await user.delete()
        Logger.log(message: "Authenticated user deleted successfully", event: .info)
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
                ssoUser.send(completion: .failure(SignInWithAppleError.credentialError))
                return
            }
            
            guard let appleIdToken = appleIDCredential.identityToken else {
                Logger.log(message: "Unable to fetch identity token", event: .debug)
                ssoUser.send(completion: .failure(SignInWithAppleError.credentialError))
                return
            }
            
            guard let appleIdTokenString = String(data: appleIdToken, encoding: .utf8) else {
                Logger.log(message: "Unable decode token string from data", event: .debug)
                ssoUser.send(completion: .failure(SignInWithAppleError.credentialError))
                return
            }
            
            // Clear any existing auth state
            try? Auth.auth().signOut()
            
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
        let nsError = error as NSError
        
        // Handle user cancellation specifically
        if nsError.code == ASAuthorizationError.canceled.rawValue {
            Logger.log(message: "User cancelled sign in", event: .debug)
            ssoUser.send(completion: .failure(SignInWithAppleError.cancelled))
            return
        }
        
        Logger.log(message: "Error authenticating: \(error.localizedDescription)", event: .error)
        ssoUser.send(completion: .failure(SignInWithAppleError.authenticationError(error.localizedDescription)))
    }
}
