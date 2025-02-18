import SwiftUI
import RevenueCat
import RevenueCatUI

enum SubscriptionTheme {
    case muayThai
}


struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseManager: PurchasesManager
    @State private var isLoading = false
    
    #if DEBUG
    private let showDebugButton = true
    #else
    private let showDebugButton = false
    #endif
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    .black,
                    .brand.opacity(0.3),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Perfect Your Jab")
                            .font(.special(.title, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .padding(.top, 40)
                    
                    // Value Props
                    VStack(spacing: 24) {
                        ValuePropCard(
                            icon: "target",
                            title: "AI-Powered Analysis",
                            description: "Get instant, precise feedback on every punch."
                        )
                        
                        ValuePropCard(
                            icon: "bolt.fill",
                            title: "Train Like a Pro",
                            description: "Perfect your form with detailed technique analysis."
                        )
                        
                        ValuePropCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Track Progress",
                            description: "See your improvements with detailed stats and metrics."
                        )
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 16) {
                        if let offering = purchaseManager.currentOffering {
                            if let monthly = offering.monthly {
                                Text(monthly.storeProduct.localizedPriceString + "/month")
                                    .font(.special(.title2, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Cancel anytime")
                                    .font(.special(.subheadline, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .padding(.vertical)
                    
                    // CTA Button
                    Button {
                        Task {
                            isLoading = true
                            do {
                                // Directly initiate a new purchase flow.
                                if let offering = purchaseManager.currentOffering,
                                   let monthly = offering.monthly {
                                    try await purchaseManager.purchaseSubscription(.monthly)
                                    dismiss()
                                } else {
                                    // Optionally, log or handle the absence of a valid offering.
                                    print("DEBUG: No valid offering found.")
                                }
                            } catch {
                                print("DEBUG: In-App Purchase flow error: \(error.localizedDescription)")
                            }
                            isLoading = false
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(purchaseManager.trialStatus == .eligible ? "Start Free Trial" : "Subscribe Now")
                                    .font(.special(.title3, weight: .bold))
                                
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.brand)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: .brand.opacity(0.5), radius: 20)
                    }
                    .disabled(isLoading || purchaseManager.currentOffering?.monthly == nil)
                    .padding(.horizontal)
                    
                    // Footer links
                    VStack(spacing: 12) {
                        Button("Restore Purchases") {
                            Task {
                                isLoading = true
                                await purchaseManager.fetchCustomerInfo()
                                dismiss()
                                isLoading = false
                            }
                        }
                        .font(.special(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .disabled(isLoading)
                        
                        TermsAndPrivacyPolicyView()
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical)
                }
            }
            
            // Close button
            // VStack {
            //     HStack {
            //         Spacer()
            //         Button {
            //             dismiss()
            //         } label: {
            //             Image(systemName: "xmark.circle.fill")
            //                 .font(.title2)
            //                 .foregroundColor(.white.opacity(0.7))
            //         }
            //         .padding()
            //     }
            //     Spacer()
            // }
            
            // Add debug button at the bottom
            // if showDebugButton {
            //     VStack {
            //         Spacer()
            //         Button {
            //             Task {
            //                 // Simulate successful purchase by setting both trial and entitlement
            //                 purchaseManager.trialStatus = .active
            //                 // Create a mock entitlement and set it
            //                 // let mockEntitlement = EntitlementInfo(
            //                 //     identifier: "premium",
            //                 //     isActive: true,
            //                 //     willRenew: true,
            //                 //     periodType: .normal,
            //                 //     latestPurchaseDate: Date(),
            //                 //     originalPurchaseDate: Date(),
            //                 //     expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days from now
            //                 //     store: .appStore,
            //                 //     isSandbox: true,
            //                 //     unsubscribeDetectedAt: nil,
            //                 //     billingIssueDetectedAt: nil
            //                 // )
            //                 // purchaseManager.entitlement = mockEntitlement
            //                 await purchaseManager.fetchCustomerInfo()
            //                 dismiss()
            //             }
            //         } label: {
            //             Text("Debug: Simulate Purchase")
            //                 .font(.special(.caption, weight: .medium))
            //                 .foregroundColor(.white.opacity(0.5))
            //         }
            //         .padding(.bottom, 8)
            //     }
            // }
        }
        .task {
            await purchaseManager.fetchOfferings()
        }
    }
}

// Value proposition card
private struct ValuePropCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.brand)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.special(.title3, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.special(.body, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
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


