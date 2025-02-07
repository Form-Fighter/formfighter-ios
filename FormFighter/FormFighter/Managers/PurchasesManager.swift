import Foundation
import RevenueCat
import UIKit
import SwiftUI
import Firebase
import Alamofire

class PurchasesManager: ObservableObject {
    enum PurchasesError: LocalizedError {
        case noCurrentOffering
        case noPackage
        case noPremiumEntitlement
        case cancelFailed
        
        var errorDescription: String {
            switch self {
            case .noCurrentOffering:
                "There is no current offering."
            case .noPackage:
                "There is no package to purchase."
            case .noPremiumEntitlement:
                "There is no premium entitlement."
            case .cancelFailed:
                "Unable to open subscription settings."
            }
        }
    }
    
    enum SubscriptionType {
        case weekly
        case monthly
        case quarterly
        case annual
        case lifetime
        
        
        var name: String {
            switch self {
            case .weekly:
                "Weekly"
            case .monthly:
                "Monthly"
            case .quarterly:
                "Quarterly"
            case .annual:
                "Annual"
            case .lifetime:
                "Lifetime"
            }
        }
    }
    
    enum TrialStatus {
        case eligible
        case active
        case expired
        case unknown
    }
    
    static let shared = PurchasesManager()
    
    @Published var currentOffering: Offering?
    @Published var eliteOffering: Offering?
    @Published var entitlement: EntitlementInfo?
    @Published var trialStatus: TrialStatus = .unknown
    // We are now using a new variable premiumSubscribed for IAP
    // 1. If user first open the app, it will be false
    // 2. If user is in the subscription period, it will be true
    // 3. If user's subscription expired or user cancelled within the trial period, it will be false
    @Published var premiumSubscribed: Bool = false
    @Published var eliteSubscribed: Bool = false
    @AppStorage("affiliateID") private var affiliateID: String = ""
    @Published var isStripeSubscribed: Bool = false
    
    // MARK: Useful for changing remotely the amount of free credits you give to users to try your app,
    // without having to create a new app version and pass a new review.
    var freeCreditsAmount: Int {
        if let value = currentOffering?.getMetadataValue(for: "free_credits", default: 3) {
            return value
        } else {
            Logger.log(message: "Return default Free Credits Amount not decoded from RevenueCat: \(3)", event: .warning)
            return 3
        }
        
    }
    
    // MARK: Use this to configure the opacity of the close button in the Paywall. You can use it to
    // do experiments between soft and hard paywalls.
    var closeButtonOpacity: Double {
        if let value = currentOffering?.getMetadataValue(for: "close_opacity", default: 0.5) {
            return value
        } else {
            Logger.log(message: "Returned default Close Opacity, not decoded from RevenueCat: \(1)", event: .warning)
            return 1
        }
    }
    
    // MARK: You can use the following price properties if you want to build your custom paywall or get
    // any price from somewhere within your app.
    var weeklyPrice: Double {
        if let price = currentOffering?.weekly?.storeProduct.price {
            return NSDecimalNumber(decimal: price).doubleValue
        } else {
            Logger.log(message: "Cannot obtain Weekly price, returning default value: \(2.99)", event: .warning)
            return 2.99
        }
    }
    
    var weeklyPriceLocalized: String {
        if let price = currentOffering?.weekly?.storeProduct.localizedPriceString {
            return price
        } else {
            Logger.log(message: "Cannot obtain Weekly Localized String ", event: .warning)
            return "ERROR"
        }
    }

    var quarterlyPrice: Double {
        if let price = currentOffering?.threeMonth?.storeProduct.price {
            return NSDecimalNumber(decimal: price).doubleValue
        } else {
            Logger.log(message: "Cannot obtain Quarterly price, returning default value: \(24.99)", event: .warning)
            return 24.99
        }
    }   

    var quarterlyPriceLocalized: String {
        if let price = currentOffering?.threeMonth?.storeProduct.localizedPriceString {
            return price
        } else {
            Logger.log(message: "Cannot obtain Quarterly Localized String ", event: .warning)
            return "ERROR"
        }
    }
    
    var monthlyPrice: Double {
        if let price = currentOffering?.monthly?.storeProduct.price {
            return NSDecimalNumber(decimal: price).doubleValue
        } else {
            Logger.log(message: "Cannot obtain Monthly price, returning default value: \(9.99)", event: .warning)
            return 9.99
        }
    }
    
    var monthlyPriceLocalized: String {
        if let price = currentOffering?.monthly?.storeProduct.localizedPriceString {
            return price
        } else {
            Logger.log(message: "Cannot obtain Monthly Localized String ", event: .warning)
            return "ERROR"
        }
    }
    
    var annualPrice: Double {
        if let price = currentOffering?.annual?.storeProduct.price {
            return NSDecimalNumber(decimal: price).doubleValue
        } else {
            Logger.log(message: "Cannot obtain Annual price, returning default value: \(39.99)", event: .warning)
            return 39.99
        }
    }
    
    var annualPriceLocalized: String {
        if let price = currentOffering?.annual?.storeProduct.localizedPriceString {
            return price
        } else {
            Logger.log(message: "Cannot obtain Annual Localized String ", event: .warning)
            return "ERROR"
        }
    }
    
    var lifetimePrice: Double {
        if let price = currentOffering?.lifetime?.storeProduct.price {
            return NSDecimalNumber(decimal: price).doubleValue
        } else {
            Logger.log(message: "Cannot obtain Lifetime price, returning default value: \(99.99)", event: .warning)
            return 99.99
        }
    }
    
    var lifetimePriceLocalized: String {
        if let price = currentOffering?.lifetime?.storeProduct.localizedPriceString {
            return price
        } else {
            Logger.log(message: "Cannot obtain Lifetime Localized String ", event: .warning)
            return "ERROR"
        }
    }
    
    var storedAffiliateID: String {
        UserDefaults.standard.string(forKey: "affiliateID") ?? ""
    }
    
    private init() {
        setupDebugLogging()
        setupRevenueCat()
        fetchOfferings()
        fetchCustomerInfo()
        debugPrintCustomerInfo()
    }
    
    private func setupRevenueCat() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: Const.Purchases.key)
        checkSubscribed()
        setAffiliateAttribution()
    }
    
    private func setupDebugLogging() {
        Purchases.logLevel = .debug
        Logger.log(message: "RevenueCat debug logging enabled", event: .debug)
    }
    
    func setAffiliateAttribution() {
        guard !storedAffiliateID.isEmpty else { return }
        
        let attributes = [
            "affiliate_id": storedAffiliateID
        ]
        
        print("🔍 Setting RevenueCat attributes: \(attributes)")
        Purchases.shared.setAttributes(attributes)
        
        // Get current subscriber info to verify
        Purchases.shared.getCustomerInfo { customerInfo, error in
            if let error = error {
                print("❌ Error getting customer info: \(error.localizedDescription)")
            } else {
                print("✅ RevenueCat attributes set successfully")
            }
        }
    }
    
    func debugPrintCustomerInfo() {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            if let error = error {
                print("🔴 RevenueCat Error: \(error.localizedDescription)")
                return
            }
            
            guard let info = customerInfo else {
                print("🔴 RevenueCat: No customer info available")
                return
            }
            
            print("📱 RevenueCat Debug Info:")
            print("└── Original App User ID: \(info.originalAppUserId)")
            print("└── First Seen: \(Date(timeIntervalSince1970: TimeInterval(info.originalAppUserId) ?? 0))")
            print("└── Latest Expiration Date: \(info.latestExpirationDate?.description ?? "None")")
            print("└── Active Subscriptions: \(info.activeSubscriptions)")
            print("└── All Purchased Product IDs: \(info.allPurchasedProductIdentifiers)")
            print("└── Non Subscriptions: \(info.nonSubscriptionTransactions)")
            print("└── Trial Status: \(self.trialStatus)")
        }
    }
    
    func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            if let error = error {
                Logger.log(message: error.localizedDescription, event: .error)
            } else {
                if let current = offerings?.current {
                    self?.currentOffering = current
                }
            }
        }
    }
    
    func fetchCustomerInfo() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            if let error = error {
                Logger.log(message: error.localizedDescription, event: .error)
                return
            }
            
            if let customerInfo = customerInfo {
                self?.entitlement = customerInfo.entitlements.all[Const.Purchases.premiumEntitlementIdentifier]
            }
        }
    }
    
    func checkTrialStatus() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            guard let self = self else { return }
            
            if let firstSeen = customerInfo?.originalAppUserId {
                let firstSeenDate = Date(timeIntervalSince1970: TimeInterval(firstSeen) ?? Date().timeIntervalSince1970)
                let trialEndDate = firstSeenDate.addingTimeInterval(72 * 3600) // 72 hours
                
                DispatchQueue.main.async {
                    if customerInfo?.entitlements.all[Const.Purchases.premiumEntitlementIdentifier]?.isActive == true {
                        // User is subscribed
                        self.trialStatus = .expired
                    } else if Date() < trialEndDate {
                        // Within 48-hour window
                        self.trialStatus = .active
                    } else {
                        // Trial expired
                        self.trialStatus = .expired
                    }
                }
            } else {
                // New user
                self.trialStatus = .eligible
            }
        }
    }
    
    func checkSubscribed() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            guard let self = self, let info = customerInfo else { return }
            
            if info.entitlements[Const.Purchases.premiumEntitlementIdentifier]?.isActive == true {
                self.premiumSubscribed = true
            }
            
            if info.entitlements[Const.Purchases.eliteEntitlementIdentifier]?.isActive == true {
                self.eliteSubscribed = true
            }
        }
    }
    
    var isTrialActive: Bool {
        trialStatus == .active
    }
    
    
    // MARK: Use this function to purchase manually if you build a custom paywall or purcharse
    // buttons over your app.
    func purchaseSubscription(_ type: SubscriptionType) async throws {
        if let currentOffering {
            guard let package = switch type {
            case .weekly:
                currentOffering.weekly
            case .monthly:
                currentOffering.monthly 
            case .quarterly:
                currentOffering.threeMonth
            case .annual:
                currentOffering.annual
            case .lifetime:
                currentOffering.lifetime
            } else {
                throw PurchasesError.noPackage
            }
            
            let purchaseResultData = try await Purchases.shared.purchase(package: package)
            
            if let entitlement = purchaseResultData.customerInfo.entitlements.all[Const.Purchases.premiumEntitlementIdentifier] {
                Logger.log(message: "Premium purchased!", event: .info)
                Tracker.purchasedPremium()
                
                // Wrap UI state updates in MainActor.run
                await MainActor.run {
                    self.entitlement = entitlement
                    self.checkSubscribed()
                }
                
                
            
        } else {
            throw PurchasesError.noCurrentOffering
        }
    }
    }
    
    func cancelSubscription() async throws {
        // Fetch the latest customer info
        let customerInfo = try await Purchases.shared.customerInfo()
        
        // Get all active subscriptions
        guard let activeSubscription = customerInfo.activeSubscriptions.first else {
            throw NSError(domain: "com.formfighter", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No active subscription found"
            ])
        }
        
        Logger.log(message: "Attempting to cancel subscription: \(activeSubscription)", event: .info)
        
        // For anonymous users, just reset instead of logout
        if customerInfo.originalAppUserId.starts(with: "$RCAnonymousID:") {
            Logger.log(message: "Anonymous user detected, performing reset", event: .info)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                Purchases.shared.logOut { customerInfo, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        } else {
            // For logged-in users, perform logout
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                Purchases.shared.logOut { customerInfo, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
        
        // Fetch fresh customer info
        await self.fetchCustomerInfo()
        
        // Clear local state
        self.entitlement = nil
        self.currentOffering = nil
        
        // Explicitly set trial status to expired
        DispatchQueue.main.async {
            self.trialStatus = .expired
        }
        
        // Notify observers
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
        
        Logger.log(message: "Successfully cancelled subscription", event: .info)
    }
    
    // MARK: - Debug Functions
    
    func resetCustomerInfo() {
        Task {
            do {
                // Reset the customer info in RevenueCat
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    Purchases.shared.logOut { customerInfo, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
                
                // Fetch fresh customer info
                await self.fetchCustomerInfo()
                
                // Clear local state
                self.entitlement = nil
                self.currentOffering = nil
                
                Logger.log(message: "Successfully reset customer info", event: .info)
            } catch {
                Logger.log(message: "Failed to reset customer info: \(error.localizedDescription)", event: .error)
            }
        }
    }
    
    func updateRevenueCatEmail(_ email: String?) {
        Purchases.shared.setEmail(email)
    }
    
    func checkUserSubscriptionAndTokens(user: User) {
        // Check if the user has a Stripe account using the correct property
        if let stripeCustomerId = user.stripeCustomerId, !stripeCustomerId.isEmpty {
            // Perform checks related to Stripe
            print("User has a Stripe account: \(stripeCustomerId)")
            // Add logic to check subscription status and tokens
        } else {
            print("User does not have a Stripe account.")
        }
        
        // Check if the user has an active subscription
        if let subscriptionStatus = user.subscriptionId, !subscriptionStatus.isEmpty {
            print("User has an active subscription: \(subscriptionStatus)")
            // Add logic to verify subscription status
        } else {
            print("User does not have an active subscription.")
        }
        
        // Check user's token balance
        if let tokens = user.tokens, tokens > 0 {
            print("User has \(tokens) tokens.")
        } else {
            print("User has no tokens.")
        }
    }
    
    func checkStripeSubscription(user: User, completion: @escaping (Bool) -> Void) {
        guard let stripeCustomerId = user.stripeCustomerId, let subscriptionId = user.subscriptionId else {
            completion(false)
            return
        }
        
        // Define the endpoint URL
        let url = "https://www.form-fighter.com/api/check-subscription"
        
        // Define the parameters
        let parameters: [String: Any] = [
            "customerId": stripeCustomerId,
            "subscriptionId": subscriptionId
        ]
        
        // Make the request using Alamofire
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let isActive = json["isActive"] as? Bool {
                        DispatchQueue.main.async {
                            self.isStripeSubscribed = isActive
                            completion(isActive)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isStripeSubscribed = false
                            completion(false)
                        }
                    }
                case .failure(let error):
                    print("Error checking subscription status: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isStripeSubscribed = false
                        completion(false)
                    }
                }
            }
    }
}
