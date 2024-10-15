import SwiftUI
import Firebase
import FirebaseAnalytics
import FirebaseCore
import WishKit
import TipKit

@main
struct FormFighterApp: App {
    
    // MARK: We store in UserDefaults wether the user completed the onboarding and the chosen GPT language.
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("gptLanguage") var gptLanguage: GPTLanguage = .english
    @AppStorage("systemThemeValue") var systemTheme: Int = ColorSchemeType.allCases.first?.rawValue ?? 0
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
   // @StateObject var purchasesManager = PurchasesManager.shared
    @StateObject var authManager = AuthManager()
    @StateObject var userManager = UserManager.shared
    
    init() {
        setupFirebase()
        setupWishKit()
        setupTips()
//        debugActions()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    onboarding
                    // MARK: - If you want to configure Crashlytics, uncomment the line below and comment 'onboarding' above.
                    // configureCrashlytics
                    
                    // MARK: - If you don't need User Authentication, remove the following conditionals
                    // and just show 'tabs' view
                } else if userManager.isAuthenticated {
                    tabs
                } else {
                    LoginView(showPaywallInTheOnboarding: false)
                }
            }
            .preferredColorScheme(selectedScheme)
           // .environmentObject(purchasesManager)
            .environmentObject(authManager)
            .environmentObject(userManager)
            .onChange(of: scenePhase) { newScenePhase in
                switch newScenePhase {
                case .active:
                //    purchasesManager.fetchCustomerInfo()
                    userManager.setAuthenticationState()
                default:
                    break
                }
            }
        }
    }
    
    var onboarding: some View {
        NavigationStack {
            // MARK: - You can change the type of onboarding you want commenting and uncommenting the views.
             //MultiplePagesOnboardingView()
            OnePageOnboardingView()
        }
    }
    
    var tabs: some View {
        // MARK: - Add or remove here as many views as tabs you need. It is recommended maximum 5 tabs.
        NavigationStack {
            TabView {
                VisionView()
                // MARK: - You can download the official app from Apple 'SF Symbols' to explore the whole catalog of system images.
                    .tabItem { Label("Analyze", systemImage: "eyes") }
                   
                ProfileView(vm: ProfileVM())
                    .tabItem { Label("Profile", systemImage: "person") }
            
                SettingsView(vm: SettingsVM())
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .tint(.brand)
        }
    }
    
#if DEBUG
    var configureCrashlytics: some View {
        
        TestCrashlyticsView()
        
    }
#endif
    
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
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        // MARK: - This code bellow to prevent sending analytics events while debugging or in TestFlight builds
        // to prevent fake data. You can comment it if you wish.
        // Also comment them (or set to true) to test if Analytics is working for the first time.
#if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
#endif
        if isTestFlight() {
            Analytics.setAnalyticsCollectionEnabled(false)
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
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        
        return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
    }
}
