import Foundation
import FirebaseAuth
import UIKit
import Combine

enum UserManagerError: LocalizedError {
    case notExists
}

class UserManager: ObservableObject {
    static let shared: UserManager = UserManager()
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isSubscriptionActive = false
    @Published var purchasesManager: PurchasesManager
    let firestoreService: DatabaseServiceProtocol
    var entitlementCancellable: AnyCancellable?
    
    private init(user: User? = nil,
                 isAuthenticated: Bool = false,
                 firestoreService: DatabaseServiceProtocol = FirestoreService(),
                 purchasesManager: PurchasesManager = PurchasesManager.shared) {
        self.user = user
        self.isAuthenticated = isAuthenticated
        self.firestoreService = firestoreService
        self.purchasesManager = purchasesManager
        
        setAuthenticationState()
        setFirebaseAuthUser()
        subscribeToCurrentEntitlement()
        
        Task {
            try? await fetchAllData()
        }
    }
    
    func fetchAllData() async throws {
        try await fetchUserInfo()
    }
    
    func createNewUserInDatabase() async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
        let newUser = User(id: currentUser.uid, name: currentUser.displayName ?? "", email: currentUser.email ?? "")
        
        try await firestoreService.createUser(userID: newUser.id, with: newUser)
    }
    
    func setFirebaseAuthUser() {
        if let currentUser = Auth.auth().currentUser {
            self.user = User(id: currentUser.uid, name: "", email: "")
        } else {
            Logger.log(message: "There is no current Auth user", event: .error)
        }
    }
    
    func setAuthenticationState() {
        if let _ = Auth.auth().currentUser {
            Logger.log(message: "🟢 Authenticated set to TRUE", event: .debug)
            isAuthenticated = true
        } else {
            Logger.log(message: "🔴 Authenticated set to FALSE", event: .debug)
            isAuthenticated = false
        }
    }
    
    @MainActor
    func fetchUserInfo() async throws {
        guard let currentUser = user else {
            Logger.log(message: "User is nil", event: .error)
            return
        }
        do {
            guard let fetchedUser = try await firestoreService.fetchUser(userID: currentUser.id) else {
                Logger.log(message: "User does not exists in the database", event: .error)
                throw UserManagerError.notExists
            }
            self.user = fetchedUser
            Logger.log(message: "User \(fetchedUser.id) fetched successfully", event: .debug)
        } catch {
            Logger.log(message: error.localizedDescription, event: .error)
            throw error
        }
    }
    
    func deleteUserData() {
        firestoreService.deleteUser(userID: userId)
    }
    
    func resetUserProperties() {
        user = nil
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    
    func requestReviewManually() {
        let url = "https://apps.apple.com/app/id\(Const.appStoreAppId)?action=write-review"
        guard let writeReviewURL = URL(string: url)
        else { return }
        
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
    
    // Listen to premium entitlement changes, in order to limit the user capabilities when detect whether
    // it is subscribed or nor.
    private func subscribeToCurrentEntitlement() {
        entitlementCancellable = purchasesManager.$entitlement.sink { [weak self] entitlement in
            guard let entitlement else {
                self?.isSubscriptionActive = false
                return
            }
            
            if entitlement.isActive {
                Logger.log(message: "Active entitlement \(entitlement.identifier) received in subscription", event: .debug)
                self?.isSubscriptionActive = true
            } else {
                Logger.log(message: "Inactive entitlement received in subscription", event: .debug)
                self?.isSubscriptionActive = false
            }
        }
    }
    
}

extension UserManager {
    var userId: String {
        user?.id ?? ""
    }
    
    var email: String {
        user?.email ?? ""
    }
    
    var name: String {
        get { user?.name ?? "unknown" }
        set { user?.name = newValue }
    }
    
}
