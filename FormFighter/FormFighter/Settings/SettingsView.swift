import SwiftUI
import WishKit
import TipKit

struct SettingsView: View {
    @AppStorage("gptLanguage") var gptLanguage: GPTLanguage = .english
    @AppStorage("systemThemeValue") var systemTheme: Int = ColorSchemeType.allCases.first?.rawValue ?? 0
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject var vm: SettingsVM
    @FocusState private var nameTextFieldFocused: Bool
    @State var copiedToClipboard = false
    @State var isShowingPaywall = false
    
    @State private var deleteUserTextConfirmation = ""
    
    var body: some View {
        List {
            Group {
                // MARK: Customize the Settings View with as many sections as you want
                premium
                settings
                info
                userInfo
                madeBy
            }
            .listRowBackground(colorScheme == .dark ? Color.brand.opacity(0.03) : Color.brand.opacity(0.05))
        }
        .scrollDismissesKeyboard(.interactively)
        .font(.special(.body, weight: .regular))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(.customBackground)
        .navigationTitle("Settings")
        .overlay(
            deleteAccount
        )
        .overlay {
            if copiedToClipboard {
                CopiedToClipboardView()
            }
        }
        .alert(isPresented: $vm.showAlert) {
            Alert(title: Text("Oops! Something went wrong."), message: Text(vm.alertMessage), dismissButton: .default(Text("OK")))
        }
        .fullScreenCover(isPresented: $isShowingPaywall) {
            PaywallView()
        }
    }
    
    @ViewBuilder
    var premium: some View {
        if userManager.isSubscriptionActive {
            HStack(spacing: 4) {
                Text("Premium")
                    .bold()
                PremiumBadgeView()
            }
            .frame(maxWidth: .infinity, maxHeight: 40, alignment: .trailing)
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        } else {
            Button {
                isShowingPaywall.toggle()
                Tracker.tappedUnlockPremium()
            } label: {
                PremiumBannerView(color: .brand)
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
    }
    
    var settings: some View {
        Section("Settings") {
            Menu {
                ForEach(GPTLanguage.allCases, id: \.self) { language in
                    Button(action: {
                        Tracker.changedLanguage(language: language)
                        gptLanguage = language
                    }) {
                        Text(language.displayName)
                    }
                }
            } label: {
                HStack {
                    Text("AI's Language")
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                    
                    Text(gptLanguage.displayName)
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .trailing)
                }
            }
            
            Menu {
                ForEach(ColorSchemeType.allCases, id: \.self) { colorScheme in
                    Button(action: {
                        Tracker.changedColorScheme(scheme: colorScheme)
                        systemTheme = colorScheme.rawValue
                    }) {
                        Text(colorScheme.title)
                    }
                }
            } label: {
                HStack {
                    Text("Color Scheme")
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                    
                    Text(ColorSchemeType(rawValue: systemTheme)?.title ?? "unknown")
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .trailing)
                }
            }
        }
    }
    
    var info: some View {
        Section("Info") {
            
            // MARK: WishKit, this is completely optional but nice to have to
            // grow your product in the feature regarding users demands.
            NavigationLink {
                WishKit.view
                    .onAppear {
                        Tracker.tappedSuggestFeatures()
                    }
            } label: {
                Text("💡 Suggest New Features")
            }
            
            Text("⭐️ Rate App")
                .onTapGesture {
                    Haptic.shared.lightImpact()
                    userManager.requestReviewManually()
                    Tracker.tappedRateApp()
                }
            
            NavigationLink {
                FAQView()
            } label: {
                Text("ℹ️ FAQ")
            }
            
            Text("✉️ Support")
                .onTapGesture {
                    Haptic.shared.lightImpact()
                    Tracker.tappedSendMail()
                    guard let emailUrl = URL(string: "mailto:\(Const.DeveloperInfo.contactEmail)?subject=\(Const.appName)%20Suggestion") else { return }
                    UIApplication.shared.open(emailUrl, options: [:], completionHandler: nil)
                }
        }
    }
    
    var userInfo: some View {
        Section("User") {
            LabeledContent {
                TextField("Type user's name", text: $userManager.name, onCommit: handleSubmit)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.medium)
                    .submitLabel(.done)
                    .focused($nameTextFieldFocused)
            } label: {
                Text("Name")
            }
            .popupTipShim(vm.userTip)
            
            LabeledContent {
                Text(userManager.userId)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.regular)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            } label: {
                Text("User ID")
            }
            .onTapGesture {
                showClipboardFeedback()
            }
            
            LabeledContent {
                Text(userManager.email)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.regular)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            } label: {
                Text("Email")
            }
            .onTapGesture {
                Haptic.shared.mediumImpact()
                UIPasteboard.general.string = userManager.email
                withAnimation(.snappy) {
                    copiedToClipboard = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.snappy) {
                        copiedToClipboard = false
                    }
                }
            }
            
            Button("Delete Account") {
                Tracker.tapDeletedAccount()
                vm.isShowingDeleteSignIn.toggle()
            }
            .fontWeight(.regular)
            .foregroundStyle(colorScheme == .light ? .black : .white)
            
            Button("Logout") {
                authManager.signOut(completion: { error in
                    if error == nil {
                        Tracker.loggedOut()
                        userManager.isAuthenticated = false
                    }
                })
            }
            .fontWeight(.regular)
            .foregroundStyle(.ruby)
        }
    }
    
    var deleteAccount: some View {
        ZStack {
            if vm.isShowingDeleteUserAlert {
                ZStack {
                    
                    DeleteConfirmationAlert(text: $deleteUserTextConfirmation, isPresented: $vm.isShowingDeleteUserAlert) {
                        Haptic.shared.notificationOccurred(type: .success)
                        vm.deleteUserAndLogout()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .padding(.horizontal)
                    .transition(.scale)
                }
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                .background(.black.opacity(0.75))
                .background(.thinMaterial)
                
            }
            
            if vm.isShowingDeleteSignIn {
                VStack {
                    Text("Please, before continuing with your user deletion we need you to sign in again for security reasons")
                        .font(.special(.title3, weight: .medium))
                    
                    CustomSignInWithAppleButton {
                        vm.signIn()
                    }
                    .padding()
                    
                    Button("Cancel") {
                        withAnimation {
                            vm.isShowingDeleteSignIn.toggle()
                        }
                    }
                    .font(.special(.body, weight: .semibold))
                    
                }
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                .padding(.horizontal)
                .background(.customBackground)
                .background(.thinMaterial)
            }
        }
    }
    
    var madeBy: some View {
        Group {
            Text("Made with 🩵 by ")
            +
            Text("\(Const.DeveloperInfo.name)")
                .underline()
                .bold()
        }
        .font(.special(.caption, weight: .light))
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowInsets(.init())
        .listRowBackground(Color.clear)
        .onTapGesture {
            Haptic.shared.lightImpact()
            Tracker.tappedReachDeveloper()
            if let url =  Const.DeveloperInfo.twitterUrl {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func showClipboardFeedback() {
        Haptic.shared.mediumImpact()
        UIPasteboard.general.string = userManager.userId
        withAnimation(.snappy) {
            copiedToClipboard = true
        }
        
        DispatchQueue.main.asyncAfter (deadline: .now() + 1.5) {
            withAnimation(.snappy) {
                copiedToClipboard = false
            }
        }
    }
    
    func handleSubmit() {
        if let user = userManager.user {
            Tracker.changedName()
            vm.updateUser(with: user)
        }
    }
}

@available(iOS 17, *)
struct UserTip: Tip, TipShim {
    var title: Text {
        Text("Tap to insert user name")
    }
    
    var message: Text? {
        Text("Your name will be saved in the cloud.")
    }
    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }
}

#Preview {
    SettingsView(vm: SettingsVM())
        .onAppear {
            UserManager.shared.isSubscriptionActive = false
        }
        .environmentObject(UserManager.shared)
        .environmentObject(AuthManager())
}
