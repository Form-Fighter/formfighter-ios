import SwiftUI
import RevenueCat
import RevenueCatUI

enum SubscriptionTheme {
    case muayThai
}

struct PaywallView: View {
    @EnvironmentObject private var purchasesManager: PurchasesManager
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedPackage: Package?
    @State private var isTrialEligible = false
    @State private var isLoading = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let monthlyDiscount = 25.0
    private let quarterlyDiscount = 33.0
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Train Smarter,\nFight Better")
                .font(.special(.title, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top)
            
            // Subscription options - centered, no scrolling
            if let weekly = purchasesManager.currentOffering?.weekly {
                SubscriptionOptionView(
                    package: weekly,
                    isSelected: selectedPackage?.identifier == weekly.identifier,
                    discount: nil as Double?,
                    theme: .muayThai
                ) {
                    selectedPackage = weekly
                }
                .padding(.horizontal)
            }
            
            // Purchase button
            Button(action: {
                Task { await purchaseSelected() }
            }) {
                Text(isTrialEligible ? "Unlock Free Trial" : "Choose")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .cornerRadius(12)
                    .scaleEffect(buttonScale)
            }
            .disabled(selectedPackage == nil || isLoading)
            .padding(.horizontal)
            
            if isTrialEligible, let package = selectedPackage {
                Text("Risk-free trial • then \(package.storeProduct.localizedPriceString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Bottom links
            VStack(spacing: 12) {
                Button("Restore Purchases") {
                    Task {
                        await restorePurchases()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                TermsAndPrivacyPolicyView()
            }
            .padding(.bottom)
        }
        .alert("Restore Purchases", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                buttonScale = 1.05
            }
            checkTrialEligibility()
        }
    }
    
    private func purchaseSelected() async {
        guard let package = selectedPackage else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let purchaseResult = try await Purchases.shared.purchase(package: package)
            if purchaseResult.customerInfo.entitlements.all[Const.Purchases.premiumEntitlementIdentifier]?.isActive == true {
                dismiss()
            }
        } catch {
            print("Purchase failed:", error.localizedDescription)
        }
    }
    
    private func checkTrialEligibility() {
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                print("❌ RevenueCat Offerings Error:", error.localizedDescription)
                return
            }
            
            print("📦 Current Offering:", offerings?.current?.identifier ?? "nil")
            print("📦 Available Packages:", offerings?.current?.availablePackages.map { $0.identifier } ?? [])
            
            if let product = offerings?.current?.availablePackages.first?.storeProduct {
                print("🏷 Product ID:", product.productIdentifier)
                print("🏷 Has Intro Offer:", product.introductoryDiscount != nil)
                
                Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product) { eligibility in
                    DispatchQueue.main.async {
                        self.isTrialEligible = eligibility == .eligible
                    }
                }
            }
        }
    }
    
    private func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            if customerInfo.entitlements.all[Const.Purchases.premiumEntitlementIdentifier]?.isActive == true {
                alertMessage = "Your subscription has been restored!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } else {
                alertMessage = "No active subscription found."
            }
            showAlert = true
        } catch {
            alertMessage = "Failed to restore purchases. Please try again."
            showAlert = true
        }
    }
}

struct SubscriptionOptionView: View {
    let package: Package
    let isSelected: Bool
    let discount: Double?
    let theme: SubscriptionTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                if let discount = discount {
                    HStack {
                        Text("SAVE \(Int(discount))%")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(4)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("🥊")
                            .font(.title2)
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(package.storeProduct.localizedPriceString)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                
                Text("Premium Access")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(width: 280, height: 140)
            .padding()
            .background(isSelected ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}
#Preview {
    PaywallView()
        .environmentObject(UserManager.shared)
        .environmentObject(PurchasesManager.shared)
}

