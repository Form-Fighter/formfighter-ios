import Foundation
import FirebaseAuth

extension String {
    var isValidEmail: Bool {
        // This regex is a common pattern for basic email validation.
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: self)
    }
}

class SettingsVM: ObservableObject {
    let firestoreService: DatabaseServiceProtocol
    let userManager = UserManager.shared
    let authManager: AuthManager
    let purchasesManager: PurchasesManager
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
                // Check for a valid user either in userManager or FirebaseAuth.
                let userID: String
                if let user = userManager.user, !user.id.isEmpty {
                    userID = user.id
                } else if let firebaseUser = Auth.auth().currentUser {
                    userID = firebaseUser.uid
                } else {
                    print("deleteUserAndLogout: No user found in userManager or Firebase.")
                    throw AuthError.userNotFound
                }
                print("deleteUserAndLogout: Found user ID \(userID). Deleting Firestore data...")
                
                // 1. Delete Firestore data.
                userManager.deleteUserData()
                print("deleteUserAndLogout: Firestore data deleted.")
                
                // 2. Track the deletion event.
                Tracker.deletedAccount()
                print("deleteUserAndLogout: Deletion event tracked.")
                
                // 3. Attempt to delete the Firebase Auth user.
                print("deleteUserAndLogout: Attempting to delete Firebase Auth user...")
                try await authManager.deleteUser()
                print("deleteUserAndLogout: Firebase Auth user deleted successfully.")
                
                // 4. Clean up local state.
                await MainActor.run {
                    userManager.isAuthenticated = false
                    userManager.resetUserProperties()
                }
                print("deleteUserAndLogout: Local state reset. User logged out.")
                
            } catch {
                print("deleteUserAndLogout - Initial attempt error: \(error.localizedDescription)")
                if let nsError = error as NSError?, nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("deleteUserAndLogout: Received requiresRecentLogin error. Attempting reauthentication...")
                    do {
                        try await self.reauthenticateUser()
                        print("deleteUserAndLogout: Reauthentication succeeded. Retrying deletion...")
                        try await authManager.deleteUser()
                        print("deleteUserAndLogout: Deletion after reauthentication succeeded.")
                        await MainActor.run {
                            userManager.isAuthenticated = false
                            userManager.resetUserProperties()
                        }
                        print("deleteUserAndLogout: Local state reset after reauthenticated deletion.")
                    } catch {
                        print("deleteUserAndLogout - Error after reauthentication: \(error.localizedDescription)")
                        await MainActor.run {
                            self.alertMessage = "Error deleting user after reauthentication: \(error.localizedDescription)"
                            self.showAlert = true
                        }
                    }
                } else {
                    await MainActor.run {
                        self.alertMessage = "Error deleting user: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    // Reauthentication method that leverages signInWithApple from authManager.
    func reauthenticateUser() async throws {
        print("reauthenticateUser: Starting reauthentication using signInWithApple...")
        let user = try await authManager.signInWithApple()
        print("reauthenticateUser: Reauthentication complete. Signed in as: \(user.email)")
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
        
        // Validate email if provided (and not empty)
        if let email = email, !email.isEmpty, !email.isValidEmail {
            isUpdating = false
            self.alertMessage = "Invalid email address. Please enter a valid email."
            self.showAlert = true
            return
        }
        
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
            lastTrainingDate: currentUser.lastTrainingDate,
            stripeCustomerId: currentUser.stripeCustomerId,
            membershipEndsAt: currentUser.membershipEndsAt,
            currentPeriodEnd: currentUser.currentPeriodEnd,
            subscriptionId: currentUser.subscriptionId,
            tokens: currentUser.tokens
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
}
