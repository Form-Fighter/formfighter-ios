import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var purchasesManager: PurchasesManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    VStack(spacing: 0) {
                        Image("app-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 50)
                        
                        Text("P R E M I U M")
                            .font(.special(.largeTitle, weight: .black))
                            .foregroundStyle(Color.ruby.gradient)
                    }
                    
                    //MARK: List as many features as you want. This is a Scrolling View.
                    VStack(alignment: .leading, spacing: 12) {
                        
                        PaywallFeature(title: "📸 Food macros at one shot",
                                       description: "Save time counting calories. Aim, shot and check the results.")
                        
                        PaywallFeature(title: "🥙 Unlimited meal analysis",
                                       description: "Analyze meals with the power of AI as much as you want.")
                        
                        PaywallFeature(title: "☁️ Sync Your Foods in the Cloud",
                                       description: "Store your meals and check its macros in the future.")
                        
                        PaywallFeature(title: "♥️ Support a Solo Developer",
                                       description: "This app was entirely created by 👨🏻‍💻 one person. Your support will directly contribute to my ongoing work and efforts.")
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal)
                }
            }
            
            Button("", systemImage: "xmark") {
                dismiss()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal)
            .font(.special(.title3, weight: .regular))
            .foregroundStyle(.brand.opacity(purchasesManager.closeButtonOpacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.customBackground)
        .navigationBarBackButtonHidden()
        .paywallFooter()
        .onPurchaseCompleted { customerInfo in
            if customerInfo.entitlements.all[Const.Purchases.premiumEntitlementIdentifier]?.isActive == true {
                Logger.log(message: "Premium purchased!", event: .info)
                Tracker.purchasedPremium()
                userManager.isSubscriptionActive = true
                dismiss()
            }
        }
        .onRestoreCompleted { customerInfo in
            if customerInfo.entitlements.all[Const.Purchases.premiumEntitlementIdentifier]?.isActive == true {
                Logger.log(message: "Restore purchases completed!", event: .info)
                Tracker.restoredPurchase()
                userManager.isSubscriptionActive = true
                dismiss()
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(UserManager.shared)
        .environmentObject(PurchasesManager.shared)
}
