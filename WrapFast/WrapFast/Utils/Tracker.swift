import Foundation
import FirebaseAnalytics

final class Tracker {
    
    // MARK: - Example of tracking events with or without parameters.
    // Create more or remove depending your needs.
    // The basic user flow is already covered.
    
    static func signedUp() {
        Analytics.logEvent("SignUp", parameters: nil)
    }
    
    static func loggedIn() {
        Analytics.logEvent("LogIn", parameters: nil)
    }
    
    static func loggedOut() {
        Analytics.logEvent("LogOut", parameters: nil)
    }
    
    static func createAnalysis(language: GPTLanguage) {
        Analytics.logEvent("CreateAnalysis", parameters: [
            "language": language.rawValue
        ])
    }
    
    static func changedName() {
        Analytics.logEvent("ChangeName", parameters: nil)
    }
    
    static func changedLanguage(language: GPTLanguage) {
        Analytics.logEvent("ChangeLanguage", parameters: [
            "language": language.rawValue
        ])
    }
    
    static func changedColorScheme(scheme: ColorSchemeType) {
        Analytics.logEvent("ChangeColorScheme", parameters: [
            "scheme": scheme.title
        ])
    }
    
    static func tappedSendMail() {
        Analytics.logEvent("TapSendMail", parameters: nil)
    }
    
    static func tappedSuggestFeatures() {
        Analytics.logEvent("TapSuggestFeatures", parameters: nil)
    }
    
    static func viewedPaywall(onboarding: Bool) {
        Analytics.logEvent("ViewPaywall", parameters: [
            "onboarding": onboarding
        ])
    }
    
    static func openedFaq() {
        Analytics.logEvent("OpenedFaq", parameters: nil)
    }
    
    static func tappedRateApp() {
        Analytics.logEvent("TapRateApp", parameters: nil)
    }
    
    static func tappedReachDeveloper() {
        Analytics.logEvent("TapReachDeveloper", parameters: nil)
    }
    
    static func pasted() {
        Analytics.logEvent("Paste", parameters: nil)
    }
    
    static func tappedUnlockPremium() {
        Analytics.logEvent("TapUnlockPremium", parameters: nil)
    }
    
    static func purchasedPremium() {
        Analytics.logEvent("PurchasedPremium", parameters: nil)
    }
    
    static func restoredPurchase() {
        Analytics.logEvent("RestorePurchase", parameters: nil)
    }
    
    static func tapDeletedAccount() {
        Analytics.logEvent("TappedDeleteAccount", parameters: nil)
    }
    
    static func deletedAccount() {
        Analytics.logEvent("DeletedAccount", parameters: nil)
    }
}
