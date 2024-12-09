import Foundation

class SettingsVM: ObservableObject {
    let firestoreService: DatabaseServiceProtocol
    let userManager = UserManager.shared
    let authManager: AuthManager
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var isShowingDeleteUserAlert = false
    @Published var isShowingDeleteSignIn = false
    var userTip: TipShim? = nil
    
    init(firestoreService: DatabaseServiceProtocol = FirestoreService(),
         authManager: AuthManager = AuthManager()) {
        self.firestoreService = firestoreService
        self.authManager = authManager
        
        if #available(iOS 17, *) {
            self.userTip = UserTip()
        }
        
        Task {
            try? await userManager.fetchAllData()
        }
    }
    
    func deleteUserAndLogout() {
        userManager.deleteUserData()
        Tracker.deletedAccount()
        authManager.deleteUser { [weak self] error in
            if error != nil {
                self?.alertMessage = "Error deleting user"
                self?.showAlert.toggle()
            } else {
                self?.authManager.signOut { error in
                    if error != nil {
                        self?.alertMessage = "Error signing out"
                        self?.showAlert.toggle()
                    } else {
                        self?.userManager.isAuthenticated = false
                        self?.userManager.resetUserProperties()
                    }
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
    
    func updateUserInfo(
        firstName: String,
        lastName: String,
        height: String? = nil,
        weight: String? = nil,
        reach: String? = nil,
        preferredStance: String? = nil,
        email: String? = nil
    ) {
        guard let currentUser = userManager.user else { return }
        
        let userId = currentUser.id
        let fullName = "\(firstName) \(lastName)"
        
        let updatedUser = User(
            id: userId,
            name: fullName,
            firstName: firstName,
            lastName: lastName,
            coachID: currentUser.coachID,
            myCoach: currentUser.myCoach,
            height: height ?? currentUser.height,
            weight: weight ?? currentUser.weight,
            reach: reach ?? currentUser.reach,
            preferredStance: preferredStance ?? currentUser.preferredStance,
            email: email ?? currentUser.email,
            currentStreak: currentUser.currentStreak,
            lastTrainingDate: currentUser.lastTrainingDate
        )
        
        Task {
            do {
                try await firestoreService.updateUser(userID: userId, with: updatedUser)
                
                await MainActor.run {
                    userManager.user = updatedUser
                }
                
                Logger.log(message: "User info updated successfully", event: .debug)
            } catch {
                await MainActor.run {
                    showAlert = true
                    alertMessage = "Failed to update user info"
                }
                Logger.log(message: error.localizedDescription, event: .error)
            }
        }
    }
}
