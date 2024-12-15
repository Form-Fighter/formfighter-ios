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
        
        // Request authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification authorization granted: \(granted)")
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
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
        print("📱 Will present notification: \(userInfo)")
        handleNotification(userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 Did receive notification response: \(userInfo)")
        handleNotification(userInfo)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("📱 Received remote notification: \(userInfo)")
        handleNotification(userInfo)
        completionHandler(.newData)
    }
    
    private func handleNotification(_ userInfo: [AnyHashable: Any]) {
        if let challengeId = userInfo["challengeId"] as? String {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenChallenge"),
                object: nil,
                userInfo: ["challengeId": challengeId]
            )
        } else if let feedbackId = userInfo["feedbackId"] as? String {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenFeedback"),
                object: nil,
                userInfo: ["feedbackId": feedbackId]
            )
        }
    }
    
    // Universal link handling
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
    
    // URL Scheme handling
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "formfighter" && url.host == "join" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                for item in queryItems {
                    if item.name == "affiliateCode", let itemValue = item.value {
                        print("Affiliate Code: \(itemValue)")
                        UserDefaults.standard.set(itemValue, forKey: "affiliateID")
                    }
                }
            }
        }
        return true
    }
}
