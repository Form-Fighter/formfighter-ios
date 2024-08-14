import Foundation
import RevenueCat

class PurchasesManager: ObservableObject {
    enum PurchasesError: LocalizedError {
        case noCurrentOffering
        case noPackage
        case noPremiumEntitlement
        
        var errorDescription: String {
            switch self {
            case .noCurrentOffering:
                "There is no current offering."
            case .noPackage:
                "There is no package to purchase."
            case .noPremiumEntitlement:
                "There is no premium entitlement."
            }
        }
    }
    
    enum SubscriptionType {
        case weekly
        case monthly
        case annual
        case lifetime
        
        var name: String {
            switch self {
            case .weekly:
                "Weekly"
            case .monthly:
                "Monthly"
            case .annual:
                "Annual"
            case .lifetime:
                "Lifetime"
            }
        }
    }
    
    static let shared = PurchasesManager()
    
    @Published var currentOffering: Offering?
    @Published var entitlement: EntitlementInfo?
    
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
    
    
    private init() {
        setupRevenueCat()
        fetchOfferings()
        fetchCustomerInfo()
    }
    
    private func setupRevenueCat() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: Const.Purchases.key)
    }
    
    func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            if let error {
                Logger.log(message: error.localizedDescription, event: .error)
            } else {
                if let current = offerings?.current {
                    self?.currentOffering = current
                    Logger.log(message: "Current Offering '\(current.identifier)' fetched", event: .debug)
                } else {
                    Logger.log(message: "Cannot find current offering", event: .error)
                }
            }
        }
    }
    
    func fetchCustomerInfo() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            if let error {
                Logger.log(message: error.localizedDescription, event: .error)
                return
            }
            
            if let customerInfo {
                self?.entitlement = customerInfo.entitlements.all[Const.Purchases.premiumEntitlementIdentifier]
            }
        }
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
                self.entitlement = entitlement
            } else {
                throw PurchasesError.noPremiumEntitlement
            }
            
        } else {
            throw PurchasesError.noCurrentOffering
        }
    }
}
