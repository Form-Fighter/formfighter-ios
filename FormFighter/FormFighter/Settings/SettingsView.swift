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
    @FocusState private var firstNameTextFieldFocused: Bool
    @FocusState private var lastNameTextFieldFocused: Bool
    @FocusState private var weightTextFieldFocused: Bool
    @FocusState private var heightTextFieldFocused: Bool
    @FocusState private var wingSpanTextFieldFocused: Bool

    
    @State var copiedToClipboard = false
    @State var isShowingPaywall = false
    
    @State private var deleteUserTextConfirmation = ""
    
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        List {
            Group {
                // MARK: Customize the Settings View with as many sections as you want
                // premium
              //  settings
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
            
            Toggle(isOn: .init(
                get: { notificationManager.authorizationStatus == .authorized },
                set: { newValue in
                    if newValue {
                        notificationManager.requestAuthorization()
                    } else {
                        // Open system settings since we can't programmatically disable notifications
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                }
            )) {
                HStack {
                    Text("Notifications")
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                    
                    if notificationManager.authorizationStatus == .authorized {
                        Text("On")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Text("Off")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
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
            
//            Text("⭐️ Rate App")
//                .onTapGesture {
//                    Haptic.shared.lightImpact()
//                    userManager.requestReviewManually()
//                    Tracker.tappedRateApp()
//                }
            
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
    
//    var wingspanfeet: Double {
//            let cm = Double(userManager.wingSpan) ?? 0
//            return cm * 0.0328084
//        }
//
//    var heightInFeetAndInches: (feet: Int, inches: Int) {
//            let totalInches = Int(userManager.height) ?? 0
//            let feet = totalInches / 12
//            let inches = totalInches % 12
//            return (feet, inches)
//        }
    
    var userInfo: some View {
        Section("Fighter Info") {
//            LabeledContent {
//                TextField("Type your name", text: $userManager.name, onCommit: handleSubmit)
//                    .multilineTextAlignment(.trailing)
//                    .fontWeight(.medium)
//                    .submitLabel(.done)
//                    .focused($nameTextFieldFocused)
//            } label: {
//                Text("Name")
//            }
//            .popupTipShim(vm.userTip)
            
            LabeledContent {
             TextField("Type your first name", text: $userManager.firstName, onCommit: handleSubmit)
                           .multilineTextAlignment(.trailing)
                           .fontWeight(.medium)
                           .submitLabel(.done)
                           .focused($firstNameTextFieldFocused)
                       } label: {
                           Text("First Name")
                       }
                       .popupTipShim(vm.userTip)
            
            LabeledContent {
                TextField("Type your last name", text: $userManager.lastName, onCommit: handleSubmit)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.medium)
                    .submitLabel(.done)
                    .focused($lastNameTextFieldFocused)
            } label: {
                Text("Last Name")
            }
            
            LabeledContent {
                TextField("Type your CoachID", text: $userManager.coachID, onCommit: handleSubmit)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.medium)
                    .submitLabel(.done)
                    .focused($lastNameTextFieldFocused)
            } label: {
                Text("Coach ID")
            }
            
            
            
//            VStack {
//                       Text("Choose Your Preferred Stance")
//                           .font(.headline)
//                           .padding(.leading)
//                
//
//                Picker("Preferred Stance", selection: $userManager.prefferedStance) {
//                           Text("Orthodox").tag("Orthodox")
//                           Text("Southpaw").tag("Southpaw")
//                       }
//                       .pickerStyle(SegmentedPickerStyle())  // Use segmented style for
//
//                   }
            
           
            
            
//            LabeledContent {
//                TextField("Type your weight in lbs", text: $userManager.weight, onCommit: handleSubmit)
//                    .keyboardType(.numberPad)
//                    .multilineTextAlignment(.trailing)
//                    .fontWeight(.medium)
//                    .submitLabel(.done)
//                    .focused($weightTextFieldFocused)
//            } label: {
//                Text("Weight")
//            }
//            .popupTipShim(vm.userTip)
//            
//            LabeledContent {
//                           TextField("Type your height in CM", text: $userManager.height, onCommit: handleSubmit)
//                               .keyboardType(.numberPad)
//                               .multilineTextAlignment(.trailing)
//                               .fontWeight(.medium)
//                               .submitLabel(.done)
//                               .focused($heightTextFieldFocused)
//                               .onChange(of: userManager.height) { newValue in
//                                   // Allow only valid numeric input during typing
//                                   let filtered = newValue.filter { "0123456789".contains($0) }
//                                   userManager.height = filtered
//                               }
//                       } label: {
//                           Text("Height in CM")
//                       }
//                       
//                       // Display the converted height in feet
//                    LabeledContent("Height in Feet and Inches", value: "\(heightInFeetAndInches.feet) ft \(heightInFeetAndInches.inches) in")

            
            
            
//            LabeledContent {
//                           TextField("Type your wingspan in CM", text: $userManager.wingSpan, onCommit: handleSubmit)
//                               .keyboardType(.numberPad)
//                               .multilineTextAlignment(.trailing)
//                               .fontWeight(.medium)
//                               .submitLabel(.done)
//                               .focused($wingSpanTextFieldFocused)
//                               .onChange(of: userManager.wingSpan) { newValue in
//                                                      // Allow only valid numeric input during typing
//                                                      let filtered = newValue.filter { "0123456789".contains($0) }
//                                                      userManager.wingSpan = filtered
//                                                  }
//                               }
//                        label: {
//                           Text("WingSpan in CM")
//                       }
//                       .popupTipShim(userManager.userTip)  // Assuming you have a popup tip or similar
                       
                       // Show the conversion to feet
//                       LabeledContent("Wing Span in Feet", value: String(format: "%.2f ft", wingspanfeet))
  
            
        
            
            
//            LabeledContent {
//                Text(userManager.userId)
//                    .multilineTextAlignment(.trailing)
//                    .fontWeight(.regular)
//                    .minimumScaleFactor(0.7)
//                    .lineLimit(1)
//            } label: {
//                Text("User ID")
//            }
//            .onTapGesture {
//                showClipboardFeedback()
//            }
            
//            LabeledContent {
//                Text(userManager.email)
//                    .multilineTextAlignment(.trailing)
//                    .fontWeight(.regular)
//                    .minimumScaleFactor(0.7)
//                    .lineLimit(1)
//            } label: {
//                Text("Email")
//            }
//            .onTapGesture {
//                Haptic.shared.mediumImpact()
//                UIPasteboard.general.string = userManager.email
//                withAnimation(.snappy) {
//                    copiedToClipboard = true
//                }
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    withAnimation(.snappy) {
//                        copiedToClipboard = false
//                    }
//                }
//            }
            
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
            
//            if let cmValue = Int(userManager.wingSpan), cmValue >= 100 && cmValue <= 250 {
//                       // Valid range, do nothing
//                   } else {
//                       // If the input is out of range or invalid, reset it
//                       userManager.wingSpan = "100"  // Reset to 100 if out of range
//                   }
//                   wingSpanTextFieldFocused = false  // Dismiss the keyboard
            
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
