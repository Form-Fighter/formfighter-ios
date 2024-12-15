import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAuth
import UserNotifications
import Alamofire

// Add enum for notification types
enum NotificationType: String, Codable {
    case system = "system"
    case feedback = "feedback"
    case streak = "streak"
    case earlyMorning = "early_morning"
    case lateNight = "late_night"
    case streakLost = "streak_lost"
    
    var title: String {
        switch self {
        case .feedback:
            return "New Feedback"
        case .system:
            return "System Update"
        case .streak:
            return "Streak Notification"
        case .earlyMorning:
            return "Early Bird! 🌅"
        case .lateNight:
            return "Night Owl! 🌙"
        case .streakLost:
            return "Streak Lost! 💔"
        }
    }
}

struct StreakNotification: Codable {
    let type: NotificationType
    let streak: Int
    let lastTrainingTime: Date
    var attemptCount: Int
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
    
    func scheduleStreakNotification(streak: Int, lastTrainingTime: Date) {
        // Cancel any existing streak notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [NotificationType.streak.rawValue])
        
        let content = UNMutableNotificationContent()
        let hour = Calendar.current.component(.hour, from: lastTrainingTime)
        
        // Customize message based on time and streak
        if hour < 6 {
            content.title = "Early Bird! 🌅"
            content.body = "We know it's early, but don't let your \(streak)-day streak slip away. Quick jab?"
        } else if hour >= 22 {
            content.title = "Night Owl! 🌙"
            content.body = "We know you're up late, but your \(streak)-day streak is worth protecting. Quick jab?"
        } else {
            content.title = "Protect Your Streak! 🔥"
            content.body = "Don't break your \(streak)-day streak. Time for today's jab!"
        }
        
        content.sound = .default
        
        // Schedule for same time tomorrow
        var components = Calendar.current.dateComponents([.hour, .minute], from: lastTrainingTime)
        components.day = Calendar.current.component(.day, from: Date()) + 1
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: NotificationType.streak.rawValue,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling streak notification: \(error)")
            } else {
                print("Successfully scheduled streak notification for tomorrow at \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
        
        // Save notification info to UserDefaults for tracking attempts
        let notification = StreakNotification(
            type: .streak,
            streak: streak,
            lastTrainingTime: lastTrainingTime,
            attemptCount: 0
        )
        saveStreakNotification(notification)
    }
    
    private func saveStreakNotification(_ notification: StreakNotification) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(notification) {
            UserDefaults.standard.set(encoded, forKey: "streak_notification")
        }
    }
    
    private func loadStreakNotification() -> StreakNotification? {
        if let data = UserDefaults.standard.data(forKey: "streak_notification") {
            let decoder = JSONDecoder()
            return try? decoder.decode(StreakNotification.self, from: data)
        }
        return nil
    }
    
    func sendChallengeNotification(message: String, challengeId: String) {
        let serverURL = URL(string: "https://www.form-fighter.com/challenge")!
        
        let payload = [
            "message": message,
            "challengeId": challengeId
        ]
        
        AF.request(serverURL,
                   method: .post,
                   parameters: payload,
                   encoder: JSONParameterEncoder.default)
            .validate()
            .responseData { response in
                switch response.result {
                case .success:
                    print("✅ Challenge notification request sent to server")
                case .failure(let error):
                    print("❌ Failed to send challenge notification request: \(error)")
                }
            }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let feedbackId = userInfo["feedbackId"] as? String {
            print("Received notification with feedbackId: \(feedbackId)")
        }
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
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenFeedback"),
                object: nil,
                userInfo: ["feedbackId": feedbackId]
            )
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