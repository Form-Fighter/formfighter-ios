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
            if isSigningIn {
                ProgressView()
                    .tint(.brand)
                    .scaleEffect(2)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            } else {
                
                // MARK: Customize the Login View as you wish.
                VStack(spacing: 32) {
                    Text("\(Const.appName)")
                        .font(.special(.extraLargeTitle, weight: .black))
                        .foregroundStyle(.brand.gradient)
                    Image("app-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 180)
                    Text("Start scanning your meals!")
                        .font(.special(.title3, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                
                VStack {
                    if canEnableFreeCredits {
                        freeCreditsText
                    }
                    
                    CustomSignInWithAppleButton {
                        signIn()
                       
                        
                    }
                    
                    TermsAndPrivacyPolicyView()
                }
                .padding(.horizontal)
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .bottom)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if showPaywallInTheOnboarding {
                Tracker.viewedPaywall(onboarding: true)
                isShowingPaywall.toggle()
            }
        }
        .fullScreenCover(isPresented: $isShowingPaywall, content: {
            PaywallView()
        })
        // MARK: Comment the line above and uncomment the line below if you prefer using the Image Paywall, like
        // in the RevenueCat Dashboard.
        //.presentPaywallIfNeeded(requiredEntitlementIdentifier: Const.Purchases.premiumEntitlementIdentifier)
        .background(.customBackground)
        
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
                Logger.log(message: "Signed in with Apple with user: \(user.email)", event: .info)
                userManager.setFirebaseAuthUser()
                try await userManager.fetchAllData()
                Tracker.loggedIn()
                hasCompletedOnboarding = true
            } catch UserManagerError.notExists {
                Logger.log(message: "There is no user in the database, creating a new one...", event: .debug)
                try await userManager.createNewUserInDatabase()
                try await userManager.fetchAllData()
                storeFreeCreditsIfNeeded()
                Tracker.signedUp()
                hasCompletedOnboarding = true
            } catch {
                Logger.log(message: error.localizedDescription, event: .error)
            }
            
            userManager.setAuthenticationState()
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
