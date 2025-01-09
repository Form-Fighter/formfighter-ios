import SwiftUI
import WishKit
import TipKit
import FirebaseFirestore

enum StanceType: String, CaseIterable {
    case orthodox = "Orthodox"
    case southpaw = "Southpaw"
}

struct SettingsView: View {
    @AppStorage("gptLanguage") var gptLanguage: GPTLanguage = .english
    @AppStorage("systemThemeValue") var systemTheme: Int = ColorSchemeType.allCases.first?.rawValue ?? 0
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var purchasesManager: PurchasesManager
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
    
    @State private var showCancelFeedbackModal = false
    @State private var cancellationFeedback = ""
    @State private var isSavingFeedback = false
    
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var localWeight: String = ""
    @State private var localReach: String = ""
    @State private var localEmail: String = ""
    @State private var selectedStance: StanceType?
    
    var body: some View {
        List {
            Group {
                info
                userInfo
               // settings
                madeBy
            }
            .listRowBackground(Color.thaiGray.opacity(0.1))
        }
        .scrollDismissesKeyboard(.interactively)
        .font(.system(.body, design: .rounded, weight: .medium))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(ThemeColors.background)
        .navigationTitle("Settings")
        .overlay(deleteAccount)
        .overlay {
            if copiedToClipboard {
                CopiedToClipboardView()
            }
        }
        .alert(isPresented: $vm.showAlert) {
            Alert(title: Text("Purchase Status"), message: Text(vm.alertMessage), dismissButton: .default(Text("OK")))
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
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
          
            Button(action: {
                notificationManager.scheduleLocalNotification(type: .system, message: "Test notification from settings!")
            }) {
                HStack {
                    Text("Test Notification")
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                    Image(systemName: "bell.badge")
                        .foregroundColor(.blue)
                }
            }
         
            
            Menu {
                ForEach(ColorSchemeType.allCases, id: \.self) { colorScheme in
                    Button(action: {
                        Tracker.changedColorScheme(scheme: colorScheme)
                        systemTheme = colorScheme.rawValue
                    }) {
                        HStack {
                            Text(colorScheme.title)
                                .foregroundStyle(ThemeColors.accent)
                        }
                        .padding(.vertical, 8)
                    }
                }
            } label: {
                HStack {
                    Text("Theme")
                        .foregroundStyle(ThemeColors.accent)
                    
                    Spacer()
                    
                    Text(ColorSchemeType(rawValue: systemTheme)?.title ?? "unknown")
                        .foregroundStyle(ThemeColors.primary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(MuayThaiButtonStyle())
            
            Toggle(isOn: .init(
                get: { notificationManager.authorizationStatus == .authorized },
                set: { newValue in
                    if newValue {
                        notificationManager.requestNotificationPermission()
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
        Section {
            Text("Form Fighter Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ThemeColors.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            
            // MARK: WishKit
            NavigationLink {
                WishKit.view
                    .onAppear {
                        Tracker.tappedSuggestFeatures()
                    }
            } label: {
                Text("💡 Suggest New Features")
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
        Group {
            // Fighter Profile Section
            Section("🥊 Fighter Profile") {
                // First Name
                LabeledContent {
                    TextField("Type your first name", 
                             text: Binding(
                                 get: { userManager.firstName },
                                 set: { newValue in
                                     userManager.firstName = newValue
                                     vm.updateUserInfo(
                                         firstName: newValue,
                                         lastName: userManager.lastName
                                     )
                                 }
                             ))
                        .multilineTextAlignment(.trailing)
                        .fontWeight(.medium)
                        .submitLabel(.done)
                        .focused($firstNameTextFieldFocused)
                } label: {
                    Text("First Name")
                }
                
                // Last Name
                LabeledContent {
                    TextField("Type your last name", 
                             text: Binding(
                                get: { 
                                    print("Getting lastName: \(userManager.lastName)")
                                    return userManager.lastName 
                                },
                                set: { newValue in
                                    print("Setting lastName to: \(newValue)")
                                    userManager.lastName = newValue
                                    vm.updateUserInfo(
                                        firstName: userManager.firstName,
                                        lastName: newValue
                                    )
                                }
                             ))
                        .multilineTextAlignment(.trailing)
                        .fontWeight(.medium)
                        .submitLabel(.done)
                        .focused($lastNameTextFieldFocused)
                } label: {
                    Text("Last Name")
                }
                
                // Height (ft'in")
                LabeledContent {
                    HStack(spacing: 4) {
                        TextField("ft", text: $heightFeet)
                            .frame(width: 30)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .onChange(of: heightFeet) { newValue in
                                // Limit to 8 feet
                                if let feet = Int(newValue), feet > 8 {
                                    heightFeet = "8"
                                    // If we're at 8 feet, inches must be 3 or less
                                    if let inches = Int(heightInches), inches > 3 {
                                        heightInches = "3"
                                    }
                                }
                                updateHeight()
                            }
                        
                        Text("'")
                        
                        TextField("in", text: $heightInches)
                            .frame(width: 30)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .onChange(of: heightInches) { newValue in
                                // If at 8 feet, limit to 3 inches
                                if let feet = Int(heightFeet), feet == 8 {
                                    if let inches = Int(newValue), inches > 3 {
                                        heightInches = "3"
                                    }
                                } else {
                                    // Otherwise limit to 11 inches
                                    if let inches = Int(newValue), inches >= 12 {
                                        heightInches = "11"
                                    }
                                }
                                updateHeight()
                            }
                        
                        Text("\"")
                    }
                } label: {
                    Text("Height")
                }
                .onAppear {
                    initializeHeightFields()
                }
                
                // Weight (lbs)
                LabeledContent {
                    TextField("Weight in lbs", text: $localWeight)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .onChange(of: localWeight) { newValue in
                            userManager.weight = newValue
                            vm.updateUserInfo(
                                firstName: userManager.firstName,
                                lastName: userManager.lastName,
                                height: userManager.height,
                                weight: newValue
                            )
                        }
                        .onAppear {
                            localWeight = userManager.weight
                        }
                } label: {
                    Text("Weight (lbs)")
                }
                
                // Updated Coach ID label
                LabeledContent {
                    Text(userManager.user?.myCoach ?? "No Coach")
                        .multilineTextAlignment(.trailing)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                } label: {
                    Text("Your Coach")
                }
 
                // Email
                LabeledContent {
                    TextField("Email", text: $localEmail)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: localEmail) { newValue in
                            vm.updateUserInfo(
                                firstName: userManager.firstName,
                                lastName: userManager.lastName,
                                email: newValue
                            )
                        }
                } label: {
                    Text("Email")
                }
                
                // Reach
                LabeledContent {
                    TextField("Optional", text: $localReach)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .onChange(of: localReach) { newValue in
                            userManager.reach = newValue
                            vm.updateUserInfo(
                                firstName: userManager.firstName,
                                lastName: userManager.lastName,
                                reach: newValue
                            )
                        }
                } label: {
                    Text("Reach (inches)")
                }
                
                // Preferred Stance
                Picker("Stance", selection: Binding<StanceType>(
                    get: { 
                        if let stance = userManager.preferredStance,
                           stance.lowercased() == "southpaw" {
                            return StanceType.southpaw
                        }
                        return StanceType.orthodox
                    },
                    set: { (newValue: StanceType) in
                        userManager.preferredStance = newValue.rawValue
                        vm.updateUserInfo(
                            firstName: userManager.firstName,
                            lastName: userManager.lastName,
                            preferredStance: newValue.rawValue
                        )
                    }
                )) {
                    ForEach(StanceType.allCases, id: \.self) { stance in
                        Text(stance.rawValue).tag(stance)
                    }
                }
            }
            
            // Account Management Section
            Section("⚙️ Account Management") {
                // Subscription Status & Management
                if !purchasesManager.premiumSubscribed && !purchasesManager.eliteSubscribed {
                    Button {
                        isShowingPaywall.toggle()
                        Tracker.tappedUnlockPremium()
                    } label: {
                        HStack {
                            Text("Start Subscription")
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }

                 Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    HStack {
                        Text("Restore Purchases")
                            .foregroundStyle(colorScheme == .light ? .black : .white)
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
                
                subscriptionManagement
                
               
                
                Button(role: .destructive) {
                    Task {
                        try? await authManager.signOut { error in
                            if error == nil {
                                userManager.isAuthenticated = false
                                userManager.resetUserProperties()
                            }
                        }
                    }
                } label: {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
                
                Button(role: .destructive) {
                    vm.isShowingDeleteUserAlert = true
                } label: {
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showCancelFeedbackModal) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Before You Go...")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("We'd love to know why you're considering cancelling:")
                        .multilineTextAlignment(.center)
                    
                    TextEditor(text: $cancellationFeedback)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button("Submit & Cancel") {
                        isSavingFeedback = true
                        Task {
                            await saveCancellationFeedback()
                            showCancelFeedbackModal = false
                            isSavingFeedback = false
                        }
                    }
                    .foregroundColor(.red)
                    .padding()
                    .disabled(isSavingFeedback)
                    .overlay {
                        if isSavingFeedback {
                            ProgressView()
                        }
                    }
                    
                    Button("Keep Subscription") {
                        showCancelFeedbackModal = false
                    }
                    .padding()
                }
                .navigationBarItems(trailing: Button("Close") {
                    showCancelFeedbackModal = false
                })
            }
        }
        .onAppear {
            initializeFields()
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
        guard let user = userManager.user else { return }
        vm.updateUserInfo(firstName: user.firstName, lastName: user.lastName)
        firstNameTextFieldFocused = false
        lastNameTextFieldFocused = false
    }
    
    private func restorePurchases() async {
        do {
            await purchasesManager.fetchCustomerInfo()
            
            if purchasesManager.premiumSubscribed || purchasesManager.eliteSubscribed {
                vm.alertMessage = "Your subscription has been restored!"
            } else {
                vm.alertMessage = "No active subscription found."
            }
            vm.showAlert = true
        } catch {
            vm.alertMessage = "Failed to restore purchases. Please try again."
            vm.showAlert = true
        }
    }
    
    var subscriptionManagement: some View {
        Group {
    


             if purchasesManager.premiumSubscribed || purchasesManager.eliteSubscribed {
                Button(role: .destructive) {
                    showCancelFeedbackModal = true
                } label: {
                    HStack {
                        Text("Cancel Subscription")
                            .foregroundColor(.red)
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func saveCancellationFeedback() async {
        do {
            // Save feedback if provided
            if !cancellationFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let db = Firestore.firestore()
                let feedbackData: [String: Any] = [
                    "userId": userManager.userId,
                    "feedback": cancellationFeedback,
                    "timestamp": FieldValue.serverTimestamp(),
                    "userEmail": userManager.user?.email ?? "Unknown",
                    "subscriptionType": purchasesManager.currentOffering?.identifier ?? "Unknown"
                ]
                
                try await db.collection("subscriptionFeedback").addDocument(data: feedbackData)
                Tracker.subscriptionCancellationFeedback(feedback: cancellationFeedback)
            }
            
            // Cancel subscription
            try await purchasesManager.cancelSubscription()
            
            // Reset customer info
            purchasesManager.resetCustomerInfo()
            
            // Show success message
            vm.alertMessage = "Your subscription has been cancelled."
            vm.showAlert = true
            
            // Close the modal
            showCancelFeedbackModal = false
        } catch {
            Logger.log(message: "Failed to process cancellation: \(error.localizedDescription)", event: .error)
            vm.alertMessage = "Failed to cancel subscription. Please try again."
            vm.showAlert = true
        }
        
        isSavingFeedback = false
    }
    
    private func initializeHeightFields() {
        if heightFeet.isEmpty || heightInches.isEmpty {
            let totalInches = Int(userManager.height) ?? 0
            heightFeet = "\(totalInches / 12)"
            heightInches = "\(totalInches % 12)"
        }
    }
    
    private func updateHeight() {
        let feet = Int(heightFeet) ?? 0
        let inches = Int(heightInches) ?? 0
        let totalInches = (feet * 12 + inches).description
        
        // Only update if the value has actually changed
        if userManager.height != totalInches {
            userManager.height = totalInches
            vm.updateUserInfo(
                firstName: userManager.firstName,
                lastName: userManager.lastName,
                height: totalInches,
                weight: userManager.weight
            )
        }
    }
    
    private func initializeFields() {
        localReach = userManager.reach
        localEmail = userManager.email
        if let stance = userManager.preferredStance {
            selectedStance = stance.lowercased() == "southpaw" ? .southpaw : .orthodox
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
