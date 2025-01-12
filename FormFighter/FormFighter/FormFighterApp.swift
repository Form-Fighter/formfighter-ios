import SwiftUI
import Firebase
import FirebaseAnalytics
import FirebaseCore
import WishKit
import TipKit
import FirebaseFirestore
import FirebaseMessaging

@main
struct FormFighterApp: App {
    
    // MARK: We store in UserDefaults wether the user completed the onboarding and the chosen GPT language.
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("gptLanguage") var gptLanguage: GPTLanguage = .english
    @AppStorage("systemThemeValue") var systemTheme: Int = ColorSchemeType.allCases.first?.rawValue ?? 0
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var purchasesManager = PurchasesManager.shared
    @StateObject var authManager = AuthManager()
    @StateObject var userManager = UserManager.shared
    @StateObject var feedbackManager = FeedbackManager.shared
    @State private var pendingCoachId: String?
    @State private var showCoachConfirmation = false
    @State private var showSplash = true
    @State private var selectedTab: TabIdentifier = .profile
    @State private var pendingFeedbackId: String?
    
    let cameraManager = CameraManager() // Create an instance of CameraManager
    
    private var db: Firestore!
    
    // Add class-level delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    init() {
        setupFirebase()
        db = Firestore.firestore()
        setupWishKit()
        setupTips()
//        debugActions()
        
        // Force solid navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ThemeColors.background)
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(ThemeColors.primary)
        
        setupCrashlytics()
    }
    
    var normalUI: some View {
        TabView(selection: $selectedTab) {
            VisionView()
                .tabItem {
                    Label("Train", systemImage: "figure.boxing")
                        .foregroundStyle(ThemeColors.primary)
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(ThemeColors.background, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Train")
                            .font(.headline)
                            .foregroundColor(ThemeColors.primary)
                    }
                }
                .tag(TabIdentifier.vision)
           
            ProfileView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(ThemeColors.primary)
                }
                .tag(TabIdentifier.profile)

            ChallengeView()
                .tabItem { 
                    Label("Challenge", systemImage: "trophy.fill")
                        .foregroundStyle(ThemeColors.primary)
                }
                .tag(TabIdentifier.challenge)

            SettingsView(vm: SettingsVM())
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                        .foregroundStyle(ThemeColors.primary)
                }
                .tag(TabIdentifier.settings)
        }
        .tint(ThemeColors.primary)
        .background(ThemeColors.background)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(ThemeColors.background, for: .tabBar)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    Group {
                        // if !hasCompletedOnboarding {
                        //     onboarding
                        // } else if !userManager.isAuthenticated {
                        //     LoginView(showPaywallInTheOnboarding: false)
                        // } else if isTestFlight() || (purchasesManager.premiumSubscribed || purchasesManager.eliteSubscribed) {
                        //     normalUI
                        // } else {
                        //     PaywallView()
                        // }
                         if !hasCompletedOnboarding {
                            onboarding
                        } else if !userManager.isAuthenticated {
                            LoginView(showPaywallInTheOnboarding: false)
                        } else {
                            normalUI
                        } 
                    }
                    .opacity(showSplash ? 0 : 1)
                    
                    if showSplash {
                        SplashScreenView()
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showSplash = false
                                    }
                                }
                            }
                    }
                }
                .preferredColorScheme(selectedScheme)
                .environmentObject(purchasesManager)
                .environmentObject(authManager)
                .environmentObject(userManager)
                .environmentObject(feedbackManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .alert("Join Team", isPresented: $showCoachConfirmation) {
                    Button("Cancel", role: .cancel) {
                        pendingCoachId = nil
                    }
                    Button("Join") {
                        assignCoach()
                    }
                } message: {
                    if let coachId = pendingCoachId {
                        Text("Would you like to join Coach \(coachId)'s team?")
                    }
                }
                .onChange(of: scenePhase) { newScenePhase in
                    switch newScenePhase {
                    case .active:
                    //    purchasesManager.fetchCustomerInfo()
                        userManager.setAuthenticationState()
                    default:
                        break
                    }
                }
                .onAppear {
                    Tracker.appOpened()
                    Tracker.appSessionBegan()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        Tracker.appSessionEnded()
                    }
                }
                .onChange(of: userManager.isAuthenticated) { isAuth in
                    // if isAuth && (purchasesManager.premiumSubscribed || purchasesManager.eliteSubscribed) {
                    //     checkAndHandlePendingChallenge()
                    // }
                     if isAuth {
                        checkAndHandlePendingChallenge()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChallenge"))) { notification in
                    if let challengeId = notification.userInfo?["challengeId"] as? String {
                        selectedTab = .challenge
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToProfile"))) { _ in
                    selectedTab = .profile
                }
            }
            .environment(\.tabSelection, $selectedTab)
        }
    }
    
    var onboarding: some View {
        NavigationStack {
            // MARK: - You can change the type of onboarding you want commenting and uncommenting the views.
             //MultiplePagesOnboardingView()
            OnePageOnboardingView()
        }
    }
    
    var selectedScheme: ColorScheme? {
        guard let theme = ColorSchemeType(rawValue: systemTheme) else { return nil}
        switch theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    // MARK: Uncomment this method in init() to execute utility actions while developing your app.
    // For example, resetting the onboarding state, deleting free credits from the keychain, etc
    // Feel free to add or comment as many as you need.
    private func debugActions() {
        #if DEBUG
//        KeychainManager.shared.deleteFreeExtraCredits()
//        KeychainManager.shared.setFreeCredits(with: Const.freeCredits)
//        KeychainManager.shared.deleteAuthToken()
//        hasCompletedOnboarding = false
        
        if #available(iOS 17.0, *) {
            // This forces all Tips to show up in every single execution.
            Tips.showAllTipsForTesting()
        }
        
        #endif
    }
    
    private func setupFirebase() {
        // Only configure Firebase once
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            
            // Configure analytics and crashlytics
            #if DEBUG
                Analytics.setAnalyticsCollectionEnabled(false)
                print("Analytics disabled in DEBUG mode")
            #else
                Analytics.setAnalyticsCollectionEnabled(!isTestFlight())
                print("Analytics enabled in RELEASE mode")
            #endif
            
            // Configure Crashlytics
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
            
            // Configure Messaging
            Messaging.messaging().isAutoInitEnabled = true
        }
    }
    
    // Customer Feedback Support.
    // https://github.com/wishkit/wishkit-iosse
    private func setupWishKit() {
        WishKit.configure(with: Const.WishKit.key)
        
        // Show the status badge of a feature request (e.g. pending, approved, etc.).
        WishKit.config.statusBadge = .show

        // Shows full description of a feature request in the list.
        WishKit.config.expandDescriptionInList = true

        // Hide the segmented control.
        WishKit.config.buttons.segmentedControl.display = .hide

        // Remove drop shadow.
        WishKit.config.dropShadow = .hide

        // Hide comment section
        WishKit.config.commentSection = .hide

        // Position the Add-Button.
        WishKit.config.buttons.addButton.bottomPadding = .large

        // This is for the Add-Button, Segmented Control, and Vote-Button.
        WishKit.theme.primaryColor = .brand

        // Set the secondary color (this is for the cells and text fields).
        WishKit.theme.secondaryColor = .set(light: .brand.opacity(0.1), dark: .brand.opacity(0.05))

        // Set the tertiary color (this is for the background).
        WishKit.theme.tertiaryColor = .setBoth(to: .customBackground)

        // Segmented Control (Text color)
        WishKit.config.buttons.segmentedControl.defaultTextColor = .setBoth(to: .white)

        WishKit.config.buttons.segmentedControl.activeTextColor = .setBoth(to: .white)

        // Save Button (Text color)
        WishKit.config.buttons.saveButton.textColor = .set(light: .white, dark: .white)

    }
    
    // Check this nice tutorial for more Tip configurations:
    // https://asynclearn.medium.com/suggesting-features-to-users-with-tipkit-8128178d6114
    private func setupTips() {
        if #available(iOS 17, *) {
            try? Tips.configure([
                .displayFrequency(.immediate)
              ])
        }
    }
    
    private func isTestFlight() -> Bool {
        #if DEBUG
            print("🧪 Debug build (running from Xcode)")
            return true
        #else
            // For TestFlight and App Store builds (Release mode)
            let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
                || Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") == true 
                || Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
                || Bundle.main.bundleIdentifier?.hasSuffix(".dev") == true
                || Bundle.main.bundleIdentifier?.hasSuffix(".beta") == true
                || (Bundle.main.infoDictionary?["ProvisioningStyle"] as? String) == "Development"
                || isRunningInTestFlight()
            
            print("🧪 Release build - Environment checks:")
            print("- Receipt path: \(Bundle.main.appStoreReceiptURL?.path ?? "nil")")
            print("- Has provisioning profile: \(Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil)")
            print("- Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
            print("- Final determination: \(isTestFlight ? "TestFlight" : "App Store")")
            
            return isTestFlight
        #endif
    }
    
    private func isRunningInTestFlight() -> Bool {
        if let receiptUrl = Bundle.main.appStoreReceiptURL {
            return receiptUrl.path.contains("sandboxReceipt")
        }
        
        // Check for TestFlight environment variable
        return ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_VERSION"] == nil 
            && ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
    }
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Received deep link: \(url)")
        
        guard let linkType = DeepLinkHandler.handle(url: url) else {
            print("❌ Failed to handle deep link")
            return
        }
        
        switch linkType {
        case .challenge(let id, let referrer):
            print("🎯 Processing challenge deep link")
            print("- Challenge ID: \(id)")
            print("- Referrer: \(referrer ?? "none")")
            
            // if !userManager.userId.isEmpty && purchasesManager.premiumSubscribed || purchasesManager.eliteSubscribed {
            //     print("👤 User authenticated and premium, processing challenge...")
            //     selectedTab = .challenge
            //     savePendingChallenge(id: id, referrer: referrer)
            // } else {
            //     print("⚠️ User not logged in or not premium, saving challenge for later")
            //     savePendingChallenge(id: id, referrer: referrer)

            // }

              if !userManager.userId.isEmpty {
                print("👤 User authenticated and premium, processing challenge...")
                selectedTab = .challenge
                savePendingChallenge(id: id, referrer: referrer)
            } else {
                print("⚠️ User not logged in or not premium, saving challenge for later")
                savePendingChallenge(id: id, referrer: referrer)

            }
            
        case .coach(let id):
            print("👥 Processing coach deep link")
            print("- Coach ID: \(id)")
            checkAndPromptForCoach(coachId: id)
            
        case .affiliate(let code):
            print("🤝 Processing affiliate deep link")
            print("- Affiliate Code: \(code)")
            UserDefaults.standard.set(code, forKey: "affiliateID")
            print("✅ Affiliate code saved to UserDefaults")
            
        case .feedback(let id):
            print("📝 Processing feedback deep link")
            print("- Feedback ID: \(id)")
            pendingFeedbackId = id
            selectedTab = .profile  // Navigate to profile tab where feedback is shown
        }
    }
    
    private func checkAndPromptForCoach(coachId: String) {
        if userManager.userId.isEmpty { return }
        let userId = userManager.userId
        
        print("🔍 Checking coach status for user: \(userId)")
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("❌ Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document,
                  document.exists else {
                print("❌ User document doesn't exist")
                return
            }
            
            let data = document.data() ?? [:]
            print("📄 User data: \(data)")
            
            // Check if myCoach field exists and has a non-nil value
            if let existingCoach = data["myCoach"] as? String,
               !existingCoach.isEmpty {
                print("👥 User already has a coach: \(existingCoach)")
                return
            }
            
            print("🔍 Checking if coach exists: \(coachId)")
            
            // Now check if the coach exists
            db.collection("users").document(coachId).getDocument { coachDoc, error in
                if let error = error {
                    print("❌ Error fetching coach document: \(error.localizedDescription)")
                    return
                }
                
                guard let coachDoc = coachDoc,
                      coachDoc.exists,
                      let coachData = coachDoc.data() else {
                    print("❌ Coach not found: \(coachId)")
                    return
                }
                
                print("✅ Coach found, showing confirmation")
                pendingCoachId = coachId
                showCoachConfirmation = true
            }
        }
    }
    
    private func assignCoach() {
        guard let coachId = pendingCoachId else {return}
            
    var userId = ""
    if userManager.userId.isEmpty { return } else {
                    userId = userManager.userId
                }
                
            
        
        db.collection("users").document(userId).setData([
            "myCoach": coachId
        ], merge: true) { error in
            if let error = error {
                print("Error assigning coach: \(error.localizedDescription)")
            } else {
                print("Coach assigned successfully")
                pendingCoachId = nil
            }
        }
    }
    
    private func logScreenView(_ screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: "FormFighterApp"
        ])
    }
    
    func setupCrashlytics() {
        Crashlytics.crashlytics().setCustomValue(UIDevice.current.systemVersion, forKey: "ios_version")
        Crashlytics.crashlytics().setCustomValue(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "", forKey: "app_version")
    }
    
    // Add these properties at the top of FormFighterApp
    struct PendingChallenge: Codable {
        let challengeId: String
        let referrerId: String?
        let timestamp: Date
    }
    
    // Add this helper method
    private func savePendingChallenge(id: String, referrer: String?) {
        let pendingChallenge = PendingChallenge(
            challengeId: id,
            referrerId: referrer,
            timestamp: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(pendingChallenge) {
            UserDefaults.standard.set(encoded, forKey: "pendingChallenge")
            print("💾 Saved pending challenge: \(id)")
        }
    }
    
    // Add this helper method
    private func checkAndHandlePendingChallenge() {
        guard let data = UserDefaults.standard.data(forKey: "pendingChallenge"),
              let pendingChallenge = try? JSONDecoder().decode(PendingChallenge.self, from: data) else {
            return
        }
        
        print("🔄 Found pending challenge: \(pendingChallenge.challengeId)")
        
        // Only process if user is authenticated and has premium or elite subscription
        // if !userManager.userId.isEmpty && (purchasesManager.premiumSubscribed || purchasesManager.eliteSubscribed) {
        //     // Just switch to challenge tab, the ChallengeView.onAppear will handle the pending challenge
        //     selectedTab = .challenge
        //     print("👤 User ready, switching to challenge tab")
        // } else {
        //     print("⏳ User not ready to process challenge (Premium: \(purchasesManager.premiumSubscribed), Elite: \(purchasesManager.eliteSubscribed), Authenticated: \(!userManager.userId.isEmpty))")
        // }

         if !userManager.userId.isEmpty {
            // Just switch to challenge tab, the ChallengeView.onAppear will handle the pending challenge
            selectedTab = .challenge
            print("👤 User ready, switching to challenge tab")
        } else {
            print("⏳ User not ready to process challenge (Premium: \(purchasesManager.premiumSubscribed), Elite: \(purchasesManager.eliteSubscribed), Authenticated: \(!userManager.userId.isEmpty))")
        }
    }
}
