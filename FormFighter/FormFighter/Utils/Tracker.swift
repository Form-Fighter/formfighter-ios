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
    
    // Add these new static properties at the top of the class
    private static var filmingStartTime: Date?
    private static var feedbackPageStartTime: Date?
    private static var processingStartTime: Date?
    private static var errorPageStartTime: Date?
    
    // Add these new methods
    static func filmingStarted() {
        filmingStartTime = Date()
        Analytics.logEvent("filming_started", parameters: nil)
    }
    
    static func processingStarted() {
        processingStartTime = Date()
        Analytics.logEvent("processing_started", parameters: nil)
    }
    
    static func processingCompleted(success: Bool) {
        guard let startTime = processingStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        Analytics.logEvent("processing_completed", parameters: [
            "duration": duration,
            "success": success
        ])
        processingStartTime = nil
    }
    
    static func errorPageViewed(errorType: String) {
        errorPageStartTime = Date()
        Analytics.logEvent("error_page_viewed", parameters: [
            "error_type": errorType
        ])
    }
    
    static func errorPageDismissed() {
        guard let startTime = errorPageStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        Analytics.logEvent("error_page_dismissed", parameters: [
            "duration": duration
        ])
        errorPageStartTime = nil
    }
    
    static func feedbackPageOpened(feedbackId: String) {
        feedbackPageStartTime = Date()
        Analytics.logEvent("feedback_page_opened", parameters: [
            "feedback_id": feedbackId
        ])
        
        // Calculate time from filming to viewing feedback if available
        if let startTime = filmingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            Analytics.logEvent("filming_to_feedback_duration", parameters: [
                "duration": duration,
                "feedback_id": feedbackId
            ])
        }
    }
    
    static func feedbackPageClosed(feedbackId: String) {
        guard let startTime = feedbackPageStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        Analytics.logEvent("feedback_page_closed", parameters: [
            "duration": duration,
            "feedback_id": feedbackId
        ])
        feedbackPageStartTime = nil
    }
    
    static func videoUploadCompleted(duration: TimeInterval, filmingDuration: TimeInterval?) {
        var parameters: [String: Any] = ["duration": duration]
        
        if let filmStart = filmingStartTime {
            let totalDuration = Date().timeIntervalSince(filmStart)
            parameters["filming_to_upload_duration"] = totalDuration
            filmingStartTime = nil // Reset after use
        }
        
        Analytics.logEvent("video_upload_completed", parameters: parameters)
    }
    
    // Add these static methods
    static func appOpened() {
        Analytics.logEvent("app_opened", parameters: nil)
    }
    
    static func appSessionBegan() {
        Analytics.logEvent("app_session_began", parameters: nil)
    }
    
    static func appSessionEnded() {
        Analytics.logEvent("app_session_ended", parameters: nil)
    }
    
    static func subscriptionCancellationFeedback(feedback: String) {
        Analytics.logEvent("subscription_cancellation_feedback", parameters: [
            "feedback": feedback
        ])
        Logger.log(message: "User submitted cancellation feedback", event: .info)
    }
}
