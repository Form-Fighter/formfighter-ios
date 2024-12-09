import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine
import OSLog
import FirebaseAnalytics  // Add this import


enum UserManagerError: LocalizedError {
    case notExists
}

class UserManager: ObservableObject {
    static let shared: UserManager = UserManager()
    @Published var user: User? {
        didSet {
            print("User property changed:")
            print("First Name: \(user?.firstName ?? "nil")")
            print("Last Name: \(user?.lastName ?? "nil")")
            print("Full Name: \(user?.name ?? "nil")")
        }
    }
    @Published var isAuthenticated = false
    @Published var isSubscriptionActive = false
    @Published var purchasesManager: PurchasesManager
    let firestoreService: DatabaseServiceProtocol
    var entitlementCancellable: AnyCancellable?
    @Published var currentStreak: Int = 0 {
        willSet {
            print("🔥 UserManager - Streak will change from \(currentStreak) to \(newValue)")
        }
        didSet {
            print("🔥 UserManager - Streak changed from \(oldValue) to \(currentStreak)")
        }
    }
    @Published var shouldShowCelebration: Bool = false
    private var userListener: ListenerRegistration?
    
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
        
        // Only request notification permissions if user is authenticated
        if Auth.auth().currentUser != nil {
            DispatchQueue.main.async {
                NotificationManager.shared.requestNotificationPermission()
            }
        }
    }
    
    func createNewUserInDatabase() async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
//        let newUser = User(id: currentUser.uid, name: currentUser.displayName ?? "", firstName: "", lastName: "", weight: "", height: "", wingSpan: "", preferredStance: "", email: currentUser.email ?? "")
        
        let newUser = User(id: currentUser.uid, name: currentUser.displayName ?? "", firstName: "", lastName: "", coachID: "", myCoach: "", email: currentUser.email ?? "")
        
        try await firestoreService.createUser(userID: newUser.id, with: newUser)
    }
    
    func setFirebaseAuthUser() {
        if let currentUser = Auth.auth().currentUser {
            //self.user = User(id: currentUser.uid, name: "", firstName: "", lastName: "", weight: "", height: "", wingSpan: "", preferredStance: "", email: "")
            self.user = User(id: currentUser.uid, name: "", firstName: "", lastName: "", coachID: "" , myCoach: "", email: "")

        } else {
            Logger.log(message: "There is no current Auth user", event: .error)
        }
    }
    
    func setAuthenticationState() {
        if let _ = Auth.auth().currentUser {
            Logger.log(message: "🟢 Authenticated set to TRUE", event: .debug)
            isAuthenticated = true
            startListening()
        } else {
            Logger.log(message: "🔴 Authenticated set to FALSE", event: .debug)
            isAuthenticated = false
            userListener?.remove()
        }
    }
    
    @MainActor
    func fetchUserInfo() async throws {
        guard let currentUser = user else {
            Logger.log(message: "User is nil", event: .error)
            return
        }
        do {
            print("Fetching user info for ID: \(currentUser.id)")
            guard let fetchedUser = try await firestoreService.fetchUser(userID: currentUser.id) else {
                Logger.log(message: "User does not exists in the database", event: .error)
                throw UserManagerError.notExists
            }
            print("Fetched user data:")
            print("First Name: \(fetchedUser.firstName)")
            print("Last Name: \(fetchedUser.lastName)")
            print("Full Name: \(fetchedUser.name)")
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
        
        // Clear FCM token from Firestore when user logs out
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(userId).updateData([
                "fcmToken": FieldValue.delete()
            ]) { error in
                if let error = error {
                    print("Error removing FCM token: \(error.localizedDescription)")
                }
            }
        }
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
    
    func trackRetentionDay() {
        guard let firstLoginDate = UserDefaults.standard.object(forKey: "firstLoginDate") as? Date else {
            UserDefaults.standard.set(Date(), forKey: "firstLoginDate")
            return
        }
        
        let daysSinceFirstLogin = Calendar.current.dateComponents([.day], from: firstLoginDate, to: Date()).day ?? 0
        
        if [1, 7, 30].contains(daysSinceFirstLogin) {
            Analytics.logEvent("retention_day", parameters: [
                "day": daysSinceFirstLogin
            ])
        }
    }
    
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        print("🔥 Starting user listener for: \(userId)")
        
        userListener = Firestore.firestore()
            .collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("❌ Error fetching user document: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                if let newStreak = document.data()?["currentStreak"] as? Int {
                    print("🔥 Received streak update: \(newStreak)")
                    DispatchQueue.main.async {
                        // If streak increased, trigger celebration
                        if newStreak > self?.currentStreak ?? 0 {
                            self?.shouldShowCelebration = true
                        }
                        self?.currentStreak = newStreak
                    }
                }
                
                // Update other user properties as needed
                if let userData = try? document.data(as: User.self) {
                    DispatchQueue.main.async {
                        self?.user = userData
                    }
                }
            }
    }
    
    deinit {
        userListener?.remove()
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
    
    var firstName: String {
        get { user?.firstName ?? "unknown" }
        set { user?.firstName = newValue }
    }
    var lastName: String {
        get { user?.lastName ?? "unknown" }
        set { user?.lastName = newValue }
    }
    
    var coachID: String {
        get { user?.coachID ?? "unknown" }
        set { user?.coachID = newValue }
    }
    
    var weight: String {
        get { user?.weight ?? "" }
        set { user?.weight = newValue }
    }
    
    var height: String {
        get { user?.height ?? "" }
        set { user?.height = newValue }
    }
    
    var reach: String {
        get { user?.reach ?? "" }
        set { user?.reach = newValue }
    }
    
    var preferredStance: String? {
        get { user?.preferredStance }
        set { user?.preferredStance = newValue }
    }
    
    var lastTrainingDate: Date? {
        get { user?.lastTrainingDate }
        set { user?.lastTrainingDate = newValue }
    }
}
