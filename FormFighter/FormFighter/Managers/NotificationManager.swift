import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAuth
import UserNotifications

// Add enum for notification types
enum NotificationType {
    case feedback
    case system
    
    var title: String {
        switch self {
        case .feedback:
            return "New Feedback"
        case .system:
            return "System Update"
        }
    }
}

// Make NotificationManager inherit from NSObject
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        getNotificationSettings()
    }
    
    func requestNotificationPermission() {
        Task {
            let granted = await requestAuthorization()
            if granted {
                await MainActor.run {
                    self.authorizationStatus = .authorized
                }
                // Register for remote notifications after authorization
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            print("Notification authorization granted: \(granted)")
            return granted
        } catch {
            print("Error requesting authorization: \(error)")
            return false
        }
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func updateFCMToken() {
        print("Requesting FCM token...")
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
                return
            }
            if let token = token {
                print("FCM Token received: \(token)")
                self?.saveFCMToken(token)
            }
        }
    }
    
    func saveFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found when saving FCM token")
            return
        }
        
        print("Saving FCM token for user: \(userId)")
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "fcmToken": token,
            "lastTokenUpdate": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token successfully saved to Firestore")
            }
        }
    }
    
    // MARK: - Local Notifications
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
    
    func testNotification() {
        // Test local notification
        scheduleLocalNotification(type: .system, message: "Test notification")
        
        print("Current authorization status: \(authorizationStatus)")
        
        // Print current FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error getting FCM token: \(error)")
            }
            if let token = token {
                print("Current FCM token: \(token)")
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
            // Handle feedback navigation here
        }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
            saveFCMToken(token)
        }
    }
} 