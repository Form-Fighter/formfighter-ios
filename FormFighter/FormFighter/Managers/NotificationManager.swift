import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAuth
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus?
    
    enum NotificationType: String {
        case feedbackProgress = "feedback_progress"
        case feedbackComplete = "feedback_complete"
        case feedbackError = "feedback_error"
        
        var title: String {
            switch self {
            case .feedbackProgress: return "Analysis in Progress"
            case .feedbackComplete: return "Analysis Complete!"
            case .feedbackError: return "Analysis Error"
            }
        }
    }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if granted {
                DispatchQueue.main.async {
                    self?.authorizationStatus = .authorized
                    self?.getNotificationSettings()
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                DispatchQueue.main.async {
                    self?.authorizationStatus = .denied
                }
            }
        }
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func updateFCMToken() {
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
                return
            }
            if let token = token {
                self?.saveFCMToken(token)
            }
        }
    }
    
    private func saveFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "fcmToken": token,
            "lastTokenUpdate": Timestamp(date: Date())
        ], merge: true) { error in
            if let error = error {
                print("Error saving FCM token: \(error)")
            } else {
                print("FCM token saved successfully")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo)
        completionHandler()
    }
    
    private func handleNotification(_ userInfo: [AnyHashable: Any]) {
        if let feedbackId = userInfo["feedbackId"] as? String {
            print("Should navigate to feedback: \(feedbackId)")
        }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            saveFCMToken(token)
        }
    }
}

// MARK: - Local Notifications
extension NotificationManager {
    func scheduleLocalNotification(type: NotificationType, message: String) {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
} 