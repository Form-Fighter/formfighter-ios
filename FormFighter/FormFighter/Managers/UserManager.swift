import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine
import OSLog
import FirebaseAnalytics  // Add this import
import SwiftUI  // Add this at the top with other imports


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
    let badgeService = BadgeService()
    var isSigningInForDeletion = false  // Add this property
    
    @AppStorage("pinnedMetrics") private var pinnedMetricsData: Data?
    @Published var pinnedMetrics: [PinnedMetric] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(pinnedMetrics) {
                pinnedMetricsData = encoded
            }
        }
    }
    
    @Published var userId: String = ""
    @Published var myCoach: String = ""
    
    @Published var currentHomework: Homework?
    
    private let db = Firestore.firestore()
    
    private init(user: User? = nil,
                 isAuthenticated: Bool = false,
                 firestoreService: DatabaseServiceProtocol = FirestoreService(),
                 purchasesManager: PurchasesManager = PurchasesManager.shared) {
        self.user = user
        self.isAuthenticated = isAuthenticated
        self.firestoreService = firestoreService
        self.purchasesManager = purchasesManager
        
        setAuthenticationState()
        subscribeToCurrentEntitlement()
        
        // Only fetch data if we're authenticated
        if Auth.auth().currentUser != nil {
            Task {
                try? await fetchAllData()
            }
        }
        
        // Load pinned metrics from UserDefaults
        if let savedMetrics = UserDefaults.standard.data(forKey: "pinnedMetrics"),
           let decodedMetrics = try? JSONDecoder().decode([PinnedMetric].self, from: savedMetrics) {
            self.pinnedMetrics = decodedMetrics
        } else {
            self.pinnedMetrics = []
        }
    }
    
    func fetchAllData() async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            // Try to fetch existing user data
            if let fetchedUser = try? await firestoreService.fetchUser(userID: currentUser.uid) {
                // Existing user flow
                let updatedUser = await MainActor.run {
                    var user = fetchedUser
                    if fetchedUser.height?.isEmpty ?? true {
                        user.height = .defaultHeight
                    }
                    if fetchedUser.weight?.isEmpty ?? true {
                        user.weight = .defaultWeight
                    }
                    return user
                }
                
                if updatedUser != fetchedUser {
                    try await firestoreService.updateUser(userID: updatedUser.id, with: updatedUser)
                }
                
                await MainActor.run {
                    self.user = updatedUser
                }
                print("Existing user fetched successfully")
            } else {
                // Create new user if doesn't exist
                let newUser = User(
                    id: currentUser.uid,
                    name: currentUser.displayName ?? "",
                    firstName: "",
                    lastName: "",
                    coachId: "",
                    myCoach: "",
                    height: .defaultHeight,
                    weight: .defaultWeight,
                    reach: "",
                    preferredStance: nil,
                    email: currentUser.email ?? "",
                    currentStreak: 0,
                    lastTrainingDate: nil
                )
                
                try await firestoreService.createUser(userID: newUser.id, with: newUser)
                await MainActor.run {
                    self.user = newUser
                }
                print("New User created successfully")
            }
            
            await MainActor.run {
                NotificationManager.shared.requestNotificationPermission()
            }
        } catch {
            print("Error in fetchAllData: \(error.localizedDescription)")
            // Don't throw here, just log the error
        }
    }
    
    func createNewUserInDatabase() async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
//        let newUser = User(id: currentUser.uid, name: currentUser.displayName ?? "", firstName: "", lastName: "", weight: "", height: "", wingSpan: "", preferredStance: "", email: currentUser.email ?? "")
        
        let newUser = User(
            id: currentUser.uid,
            name: currentUser.displayName ?? "",
            firstName: "",
            lastName: "",
            coachId: "",
            myCoach: "",
            height: "",
            weight: "",
            reach: "",
            preferredStance: nil,
            email: currentUser.email ?? "",
            currentStreak: 0,
            lastTrainingDate: nil,
            stripeCustomerId: nil,
            membershipEndsAt: nil,
            currentPeriodEnd: nil,
            subscriptionId: nil,
            tokens: 0
        )
        
        try await firestoreService.createUser(userID: newUser.id, with: newUser)
    }
    
    func setFirebaseAuthUser() {
        if let currentUser = Auth.auth().currentUser {
            //self.user = User(id: currentUser.uid, name: "", firstName: "", lastName: "", weight: "", height: "", wingSpan: "", preferredStance: "", email: "")
            self.user = User(id: currentUser.uid, name: "", firstName: "", lastName: "", coachId: "" , myCoach: "", email: "", currentStreak: 0, lastTrainingDate: nil, stripeCustomerId: nil, membershipEndsAt: nil, currentPeriodEnd: nil, subscriptionId: nil, tokens: 0)

        } else {
            Logger.log(message: "There is no current Auth user", event: .error)
        }
    }
    
    func setAuthenticationState() {
        if let _ = Auth.auth().currentUser {
            Logger.log(message: "🟢 Authenticated set to TRUE", event: .debug)
            isAuthenticated = true
            
            // Only start listening and fetch data if NOT signing in for deletion
            if !isSigningInForDeletion {
                startListening()
                Task {
                    try? await fetchAllData()
                    // Add homework fetch here
                    await fetchCurrentHomework()
                }
            }
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
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
                
                // Skip processing if this is a local change
                if document.metadata.hasPendingWrites {
                    print("📝 Skipping local change update")
                    return
                }
                
                // Process streak updates
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
                
                // Only update user data if there are actual changes
                if let userData = try? document.data(as: User.self),
                   userData != self?.user {  // Add Equatable conformance to User
                    print("👤 Received user data update")
                    DispatchQueue.main.async {
                        self?.user = userData
                    }
                }
            }
    }
    
    deinit {
        userListener?.remove()
    }
    
    // Start listening when user logs in
    func signIn(userId: String) {
        badgeService.startListening(userId: userId)
    }
    
    
    // Stop listening when user logs out
    func signOut() {
        badgeService.stopListening()
    }
    
    // Process events when they occur
    func updateStreak(_ newStreak: Int) {
        Task {
            await badgeService.processEvent(.streakUpdated(days: newStreak))
        }
    }
    
    @MainActor
    func updateUserOnMainThread(_ newUser: User) {
        self.user = newUser
    }
    
    func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let data = document?.data() {
                self?.myCoach = data["myCoach"] as? String ?? ""
            }
        }
    }
    
    func fetchCurrentHomework() async {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("📝 No user ID available for homework fetch")
            return 
        }
        
        print("📝 Fetching homework for user: \(userId)")
        let db = Firestore.firestore()
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let snapshot = try await db.collection("homework")
                .whereField("students", arrayContains: userId)
                .whereField("assignedDate", isGreaterThanOrEqualTo: today)
                .whereField("assignedDate", isLessThan: tomorrow)
                .getDocuments()
            
            print("📝 Found \(snapshot.documents.count) homework documents")
            
            let homeworkList = snapshot.documents.compactMap { doc -> Homework? in
                print("📝 Raw homework data: \(doc.data())")
                let homework = try? doc.data(as: Homework.self)
                print("📝 Decoded homework: \(String(describing: homework))")
                return homework
            }
            
            // Set the earliest incomplete homework
            DispatchQueue.main.async {
                let filteredHomework = homeworkList
                    .filter { homework in
                        let completedCount = homework.completedFeedbackIds?.count ?? 0
                        let punchCount = homework.punchCount ?? 0
                        let isIncomplete = completedCount < punchCount
                        print("📝 Homework \(String(describing: homework.id)) - completed: \(completedCount)/\(punchCount), isIncomplete: \(isIncomplete)")
                        return isIncomplete
                    }
                
                print("📝 Filtered homework count: \(filteredHomework.count)")
                
                self.currentHomework = filteredHomework
                    .sorted { h1, h2 in
                        let date1 = h1.assignedDate?.dateValue() ?? Date()
                        let date2 = h2.assignedDate?.dateValue() ?? Date()
                        return date1 < date2
                    }
                    .first
                
                print("📝 Current Homework set to: \(String(describing: self.currentHomework))")
            }
        } catch {
            print("❌ Error fetching homework: \(error)")
        }
    }
    
    func updateSubscriptionAndTokens() {
        guard let currentUser = user else {
            print("No user is currently logged in.")
            return
        }
        
      
        
        purchasesManager.checkStripeSubscription(user: currentUser) { isActive in
            if isActive {
                print("User has an active Stripe subscription.")
            } else {
                print("User does not have an active Stripe subscription.")
            }
        }
    }
}

extension UserManager {
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
    
    var coachId: String {
        get { user?.coachId ?? "unknown" }
        set { user?.coachId = newValue }
    }
    
    var weight: String {
        get { 
            let currentWeight = user?.weight ?? ""
            return currentWeight.isEmpty ? .defaultWeight : currentWeight
        }
        set { user?.weight = newValue }
    }
    
    var height: String {
        get {
            let currentHeight = user?.height ?? ""
            return currentHeight.isEmpty ? .defaultHeight : currentHeight
        }
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

struct PinnedMetric: Codable {
    let id: String
    let category: String
    let displayName: String
}

struct JabMetricQuestion {
    let question: String
    let options: [String]
    let relatedMetrics: [String: [String]] // Maps answer to metric IDs
}

let jabQuizQuestions = [
    JabMetricQuestion(
        question: "What's your most common feedback during sparring with your jab?",
        options: [
            "I get countered easily",
            "My jab lacks power",
            "I'm too slow to retract",
            "I drop my hands after jabbing"
        ],
        relatedMetrics: [
            "I get countered easily": ["Chin_Tucked_Extension", "Hand_Velocity_Extension"],
            "My jab lacks power": ["Force_Generation_Extension", "Whip_Effect_Extension"],
            "I'm too slow to retract": ["Hand_Velocity_Retraction", "Overall_Velocity_Retraction"],
            "I drop my hands after jabbing": ["Hand_Drop_Before_Extension", "Hands_Above_Shoulders_Guard"]
        ]
    ),
    JabMetricQuestion(
        question: "What aspect of your jab do you want to improve most?",
        options: [
            "Speed and explosiveness",
            "Technical form",
            "Defense while jabbing",
            "Power generation"
        ],
        relatedMetrics: [
            "Speed and explosiveness": ["Hand_Velocity_Extension", "Overall_Velocity_Extension"],
            "Technical form": ["Jab_Straight_Line_Extension", "Elbow_Straight_Line_Extension"],
            "Defense while jabbing": ["Chin_Tucked_Extension", "Rear_Hand_In_Guard_Extension"],
            "Power generation": ["Force_Generation_Extension", "Hip_Rotation_Extension"]
        ]
    ),
    JabMetricQuestion(
        question: "What's your biggest technical challenge with the jab?",
        options: [
            "My elbow flares out",
            "I telegraph my jab",
            "My footwork is off",
            "My jab isn't straight"
        ],
        relatedMetrics: [
            "My elbow flares out": ["Elbow_Flare_Extension", "Elbow_Straight_Line_Extension"],
            "I telegraph my jab": ["Hand_Drop_Before_Extension", "Motion_Sequence"],
            "My footwork is off": ["Foot_Placement_Extension", "Step_Distance_Extension"],
            "My jab isn't straight": ["Jab_Straight_Line_Extension", "Wrist_Angle_Extension"]
        ]
    ),
    JabMetricQuestion(
        question: "What do you want to add to your jab?",
        options: [
            "More snap/whip",
            "Better body rotation",
            "Smoother motion",
            "Better balance"
        ],
        relatedMetrics: [
            "More snap/whip": ["Whip_Effect_Extension", "Hand_Velocity_Extension"],
            "Better body rotation": ["Torso_Rotation_Extension", "Hip_Rotation_Extension"],
            "Smoother motion": ["Motion_Sequence", "Overall_Velocity_Extension"],
            "Better balance": ["Mean_Back_Leg_Angle_Extension", "Foot_Placement_Extension"]
        ]
    ),
    JabMetricQuestion(
        question: "What happens after you throw your jab?",
        options: [
            "I'm slow getting back to guard",
            "I'm off balance",
            "I get hit with counters",
            "My stance is compromised"
        ],
        relatedMetrics: [
            "I'm slow getting back to guard": ["Hand_Velocity_Retraction", "Return_Position_Difference_Retraction"],
            "I'm off balance": ["Mean_Back_Leg_Angle_Retraction", "Foot_Placement_Retraction"],
            "I get hit with counters": ["Rear_Hand_In_Guard_Extension", "Head_Stability_Extension"],
            "My stance is compromised": ["Leg_To_Shoulder_Width_Guard", "Mean_Back_Leg_Angle_Guard"]
        ]
    )
]



