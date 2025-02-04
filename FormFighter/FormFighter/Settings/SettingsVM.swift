import Foundation

class SettingsVM: ObservableObject {
    let firestoreService: DatabaseServiceProtocol
    let userManager = UserManager.shared
    let authManager: AuthManager
    let purchasesManager: PurchasesManager
    let tokenManager = TokenManager.shared
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var isShowingDeleteUserAlert = false
    @Published var isShowingDeleteSignIn = false
    var userTip: TipShim? = nil
    private var updateTask: Task<Void, Never>?
    private var isUpdating = false
    
    init(firestoreService: DatabaseServiceProtocol = FirestoreService(),
         authManager: AuthManager = AuthManager(),
         purchasesManager: PurchasesManager = PurchasesManager.shared) {
        self.firestoreService = firestoreService
        self.authManager = authManager
        self.purchasesManager = purchasesManager
        
        if #available(iOS 17, *) {
            self.userTip = UserTip()
        }
        
        // Task {
        //     try? await userManager.fetchAllData()
        // }
    }
    
    func deleteUserAndLogout() {
        Task {
            do {
                // 1. Check for valid userID first
                guard !userManager.userId.isEmpty else {
                    throw AuthError.userNotFound
                }
                
                // 2. Delete Firestore data first
                userManager.deleteUserData()
                
                // 3. Track the deletion
                Tracker.deletedAccount()
                
                // 4. Delete Firebase Auth user and sign out
                try await authManager.deleteUser()
                
                // 5. Clean up local state (do this last)
                await MainActor.run {
                    userManager.isAuthenticated = false
                    userManager.resetUserProperties()
                }
                
            } catch {
                await MainActor.run {
                    self.alertMessage = "Error deleting user: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    func signIn() {
        Task {
            do {
                let user = try await authManager.signInWithApple()
                DispatchQueue.main.async {
                    self.isShowingDeleteSignIn.toggle()
                    self.isShowingDeleteUserAlert.toggle()
                }
                Logger.log(message: "Signed in with Apple with user: \(user.email)", event: .info)
            } catch {
                Logger.log(message: error.localizedDescription, event: .error)
            }
        }
    }
    
    func updateUser(with user: User) {
        Task {
            do {
                try await firestoreService.updateUser(userID: user.id, with: user)
                Logger.log(message: "User updated successfully", event: .debug)
            } catch {
                Logger.log(message: error.localizedDescription, event: .error)
            }
        }
    }
    
    @MainActor func updateUserInfo(
        firstName: String,
        lastName: String,
        height: String? = nil,
        weight: String? = nil,
        reach: String? = nil,
        preferredStance: String? = nil,
        email: String? = nil
    ) {
        guard !isUpdating, let currentUser = userManager.user else { return }
        
        isUpdating = true
        
        // Cancel any pending update
        updateTask?.cancel()
        
        let updatedUser = User(
            id: currentUser.id,
            name: "\(firstName) \(lastName)",
            firstName: firstName,
            lastName: lastName,
            coachId: currentUser.coachId,
            myCoach: currentUser.myCoach,
            height: height ?? currentUser.height ?? "",
            weight: weight ?? currentUser.weight ?? "",
            reach: reach ?? currentUser.reach ?? "",
            preferredStance: preferredStance ?? currentUser.preferredStance ?? "",
            email: email ?? currentUser.email,
            currentStreak: currentUser.currentStreak,
            lastTrainingDate: currentUser.lastTrainingDate
        )
        
        // Update local state immediately
        userManager.updateUserOnMainThread(updatedUser)
        
        // If email was updated, sync with RevenueCat
        if let email = email {
            purchasesManager.updateRevenueCatEmail(email)
        }
        
        // Create new debounced update task for Firestore
        updateTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
                try await firestoreService.updateUser(userID: currentUser.id, with: updatedUser)
                isUpdating = false
            } catch {
                Logger.log(message: "Failed to update user: \(error.localizedDescription)", event: .error)
                isUpdating = false
            }
        }
    }
    
    func fetchTokensIfNeeded() {
        if let myCoach = userManager.user?.myCoach,
           let userId = userManager.user?.id,
           !myCoach.isEmpty {
            tokenManager.fetchTokenInfo(
                coachId: myCoach,
                studentId: userId
            )
        }
    }
}
