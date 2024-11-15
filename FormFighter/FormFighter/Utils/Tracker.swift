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
    
    static func notificationPermissionRequested(granted: Bool) {
        Analytics.logEvent("notification_permission", parameters: [
            "granted": granted
        ])
    }
    
    static func receivedPushNotification(type: String) {
        Analytics.logEvent("push_notification_received", parameters: [
            "type": type
        ])
    }
    
    static func feedbackViewed(feedbackId: String) {
        Analytics.logEvent("feedback_viewed", parameters: [
            "feedback_id": feedbackId
        ])
    }
    
    static func formAnalysisStarted() {
        Analytics.logEvent("form_analysis_started", parameters: nil)
    }
    
    static func formAnalysisCompleted(duration: TimeInterval) {
        Analytics.logEvent("form_analysis_completed", parameters: [
            "duration": duration
        ])
    }
    
    static func errorOccurred(domain: String, code: Int, description: String) {
        Analytics.logEvent("error_occurred", parameters: [
            "error_domain": domain,
            "error_code": code,
            "error_description": description
        ])
    }
    
    static func punchAnalysisStarted() {
        Analytics.logEvent("punch_analysis_started", parameters: nil)
    }
    
    static func punchAnalysisCompleted(success: Bool, duration: TimeInterval) {
        Analytics.logEvent("punch_analysis_completed", parameters: [
            "success": success,
            "duration": duration
        ])
    }
    
    static func videoUploaded(success: Bool, size: Int64) {
        Analytics.logEvent("video_uploaded", parameters: [
            "success": success,
            "size": size
        ])
    }
    
    static func feedbackRequested() {
        Analytics.logEvent("feedback_requested", parameters: nil)
    }
    
    static func feedbackReceived(responseTime: TimeInterval) {
        Analytics.logEvent("feedback_received", parameters: [
            "response_time": responseTime
        ])
    }
    
    static func notificationReceived(type: String) {
        Analytics.logEvent("notification_received", parameters: [
            "type": type
        ])
    }
    
    static func videoRecordingStarted() {
        Analytics.logEvent("video_recording_started", parameters: nil)
    }
    
    static func videoRecordingCompleted(duration: TimeInterval) {
        Analytics.logEvent("video_recording_completed", parameters: [
            "duration": duration
        ])
    }
    
    static func videoUploadStarted(fileSize: Int64) {
        Analytics.logEvent("video_upload_started", parameters: [
            "file_size": fileSize
        ])
    }
    
    static func videoUploadCompleted(duration: TimeInterval) {
        Analytics.logEvent("video_upload_completed", parameters: [
            "duration": duration
        ])
    }
    
    static func feedbackSubmitted(type: UserFeedbackType, rating: Double) {
        Analytics.logEvent("feedback_submitted", parameters: [
            "type": type.rawValue,
            "rating": rating
        ])
    }
}
