import SwiftUI

struct LoginView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var purchasesManager: PurchasesManager
    @State private var isSigningIn = false
    @State var isShowingPaywall = false
    
    // MARK: If this is set to true, the Paywall is showed. It is recommended show it here.
    // It is demonstrated that most of users buy during the onboarding.
    // Check this useful video for more info and pretty useful tips:
    //https://www.youtube.com/watch?v=-rAIJrgLiWw&list=PLHoc_vHOn5S0U1ZTSVmAS22YPLQkX6XWx&index=7
    @State var showPaywallInTheOnboarding: Bool
    
    var body: some View {
        ZStack {
            // Full screen black background.
            Color.black
                .ignoresSafeArea()
            
            if isSigningIn {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 32) {
                    Text("Form Fighter")
                        .font(.special(.extraLargeTitle, weight: .black))
                        .foregroundStyle(.white)
                    
                    // App logo with explicit black background.
                    Image("app-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 180)
                        .background(Color.black)
                    
                    Text("Train Smarter, Fight Better, Think like a Coach.")
                        .font(.special(.title3, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal) // Added horizontal padding for the main content.
                
                VStack {
                    // if canEnableFreeCredits {
                    //     freeCreditsText
                    // }
                    
                    CustomSignInWithAppleButton {
                        signIn()
                    }
                    
                    TermsAndPrivacyPolicyView()
                }
                .padding(.horizontal) // Added horizontal padding for the bottom section.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if showPaywallInTheOnboarding {
                Tracker.viewedPaywall(onboarding: true)
             //   isShowingPaywall.toggle()
            }
        }
        // .fullScreenCover(isPresented: $isShowingPaywall, content: {
        //    // PaywallView()
        // })
        // MARK: Comment the line above and uncomment the line below if you prefer using the Image Paywall, like
        // in the RevenueCat Dashboard.
        //.presentPaywallIfNeeded(requiredEntitlementIdentifier: Const.Purchases.premiumEntitlementIdentifier)
        .background(Color.customBackground)
    }
    
    var freeCreditsText: some View {
        Group {
            Text("Try it for ")
            +
            Text(" FREE")
                .foregroundColor(Color.brand)
                .font(.special(.title2, weight: .bold))
        }
        .font(.special(.body, weight: .regular))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
    
    // MARK: - Sign in flow
    // 1: We do Sign in with Apple with Firebase Authentication and store the Firebase Authentication User.
    // 2: We try to fetch the user data (User.swift) from Firestore.
    // (User data can be whatever you need, it is up to you)
    // 3: If the user does not exist in Firestore (first login for example), we create a new one
    // 4: We store free credits in Keychain (optional) and set onboarding flow to true
    // 5: Set app authentication state to true. This triggers show the our main app views.
    private func signIn() {
        isSigningIn = true
        
        Task {
            do {
                let user = try await authManager.signInWithApple()
                print("Signed in with Apple with user: \(user.email)")
                
                // This will handle both new and existing users
                try await userManager.fetchAllData()
                
                // Sync email with RevenueCat
                purchasesManager.updateRevenueCatEmail(user.email)
                
                // Set authentication state after data is loaded
                userManager.setAuthenticationState()
                hasCompletedOnboarding = true
                
            } catch {
                print(error.localizedDescription)
            }
            
            isSigningIn = false
        }
    }
    
    private func storeFreeCreditsIfNeeded() {
        if  canEnableFreeCredits {
            KeychainManager.shared.storeInitialFreeExtraCredits()
        }
    }
    
    private var canEnableFreeCredits: Bool {
        !userManager.isSubscriptionActive && !KeychainManager.shared.existsStoredFreeCredits()
    }
}

#Preview {
    LoginView(showPaywallInTheOnboarding: true)
        .environmentObject(UserManager.shared)
        .environmentObject(AuthManager())
        .environmentObject(PurchasesManager.shared)
}
