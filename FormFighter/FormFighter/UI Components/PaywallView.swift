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
        ZStack {
            // Add dynamic background
            LinearGradient(
                colors: [.black.opacity(0.9), Color.brand.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Enhanced header
                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                        .scaleEffect(buttonScale)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: buttonScale
                        )
                    
                    Text("Train Smarter")
                        .font(.special(.title2, weight: .black))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("Fight Better")
                        .font(.special(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 40)
                
                // Benefits section
                VStack(spacing: 16) {
                    benefitRow(icon: "checkmark.circle.fill", text: "Professional Training Programs")
                    benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track Your Progress")
                    benefitRow(icon: "video.fill", text: "HD Video Tutorials")
                }
                .padding(.vertical)

                // Modified subscription option
                if let weekly = purchasesManager.currentOffering?.weekly {
                    SubscriptionOptionView(
                        package: weekly,
                        isSelected: selectedPackage?.identifier == weekly.identifier,
                        discount: nil,
                        theme: .muayThai
                    ) {
                        selectedPackage = weekly
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonScale = 1.1
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                            buttonScale = 1.0
                        }
                    }
                    .padding(.horizontal)
                }

                // Enhanced purchase button
                Button(action: {
                    Task { await purchaseSelected() }
                }) {
                    Text(isTrialEligible ? "START FREE TRIAL NOW" : "UNLOCK PREMIUM")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
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

                // Enhanced bottom links
                VStack(spacing: 16) {
                    Button("Restore Purchases") {
                        Task { await restorePurchases() }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    
                    TermsAndPrivacyPolicyView()
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom)
            }
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
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
            Text(text)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
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
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("PREMIUM ACCESS")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    
                    Text(package.storeProduct.localizedPriceString)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("per week")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                
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

