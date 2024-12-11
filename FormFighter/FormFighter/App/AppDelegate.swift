import UIKit
import Firebase
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("AppDelegate: didFinishLaunchingWithOptions")
       
        // Set up notifications with authorization request
        UNUserNotificationCenter.current().delegate = self
        // Set messaging delegate before registering for remote notifications
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Did register for remote notifications with device token")
        
        // Set the APNS token first
        Messaging.messaging().apnsToken = deviceToken
        
        // Now that we have the APNS token, we can request the FCM token
        NotificationManager.shared.updateFCMToken()
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token refreshed: \(String(describing: fcmToken))")
        
        if let token = fcmToken {
            NotificationManager.shared.saveFCMToken(token)
        }
    }
    
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
        
        if let feedbackId = userInfo["feedbackId"] as? String {
            print("User tapped notification with feedbackId: \(feedbackId)")
            // Handle the feedbackId as needed
        }
        
        completionHandler()
    }
    
    // save affilateID from universal link
    func application(_ app: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let queryItems = components?.queryItems {
                for item in queryItems {
                    if item.name == "affiliateID", let itemValue = item.value {
                        print("Affiliate ID: \(itemValue)")
                        UserDefaults.standard.set(itemValue, forKey: "affiliateID")
                    }
                }
            }
        }
        return true
    }
}
