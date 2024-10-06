import Foundation
import SwiftUI

enum FontStyle: String {
    // MARK: - Replace with the name of the custom font you want.
    // Remember to add the font files in the Info.plist, otherwise won't work.
    // If you want to use a custom font, use it like:
    // .special(.body, weight: .regular)
    // If you want to use system font use it like:
    // .system(.body, weight: .regular)
    // In this example we use custom Fonts. If you want to switch to system fonts
    // just find and replace '.special(' with '.system('
    
    case extraLight = "BricolageGrotesque-ExtraLight"
    case light = "BricolageGrotesque-Light"
    case regular = "BricolageGrotesque-Regular"
    case medium = "BricolageGrotesque-Medium"
    case semibold = "BricolageGrotesque-SemiBold"
    case bold = "BricolageGrotesque-Bold"
    case black = "BricolageGrotesque-ExtraBold"
}

enum FontSize: CGFloat {
    // MARK: - These are suggested sized but you can tweak it as much as you wish.
    case caption2 = 11
    case caption = 12
    case footnote = 13
    case subheadline = 15
    case callout = 16
    case body = 17
    case title3 = 20
    case title2 = 22
    case title = 28
    case largeTitle = 34
    case extraLargeTitle = 36
}

enum Const {
    // MARK: - Storing the free credits in the Keychain prevents abusing of the free tier between installations because it persists.
    enum Keychain {
        static let freeCreditsKey = "free_credits"
        
        // Key used to save the authentication token received from the backend
        static let tokenKey = "token_key"
    }
    
    // MARK: - RevenueCat constants
    enum Purchases {
        // RevenueCat API Key
        static let key = "appl_tbetznaRrHwgNnEqoSLLuilMMoD"
        
        // Replace 'premium' if you created the entitlement with other name
        static let premiumEntitlementIdentifier = "premium"
        
        // Replace with links to your Privacy Policy and Terms of Service
        // Prompts to generate them using ChatGPT:
        //
        // You are an excellent lawyer.

        // I need your help to write a simple Terms of Service for my iOS app. Here is some context:
        // - Name: WrapFast
        // - Contact information: hi@jjvalino.com
        // - Description: A nutrition app that analyzes with artificial intelligence images of meals taken by the user in order to estimate macronutrients.
        // - User data collected: name, email
        // - Non-personal data collection: usage
        // - Link to privacy-policy: https://sites.google.com/view/wrapfast-privacy
        // - Governing Law: Spain
        // - Updates to the Terms: posting the new one and updating effective date

        // Please write a simple Terms of Service for my app. Add the current date. Do not add or explain your reasoning. Answer:
        
        static let termsOfServiceLink = URL(string: "https://docs.google.com/document/d/1vuu4Y77t1fuRlV9QBdG4aF25SjOK2uB8clHmQllMa5U/edit?usp=sharing")
        
        // You are an excellent lawyer.

        // I need your help to write a simple privacy policy for my iOS app. Here is some context:
        // - Name: WrapFast
        // - Description: A nutrition app that analyzes with artificial intelligence images of meals taken by the user in order to estimate macronutrients.
        // - User data collected: name, email
        // - Non-personal data collection: usage
        // - Purpose of Data Collection: improve the app
        // - Data sharing: We send the pictures to OpenAI’s API to process them. We do not save the pictures. We use cloud store in Firebase, for instance, the user profile information.
        // - Children's Privacy: we do not collect any data from children
        // - Updates to the Privacy Policy: posting the new policy and updating effective date
        // - Contact information: hi@jjvalino.com

        // Please write a simple privacy policy for my app. Add the current date.  Do not add or explain your reasoning. Answer:
        
        static let privacyPolicyLink = URL(string: "https://docs.google.com/document/d/14C0h6XD3a0C3_u2a2wZnx15bIsJobYmxezq-iS-eRrs/edit?usp=sharing")
    }
    
    // MARK: - WishKit API Key. Customer Feedback platform.
    enum WishKit {
        static let key = "8CD6171C-8CFF-49E9-B79B-0875576A3DA8"
    }
    
    enum Api {
        #if DEBUG
        // Use the baseURL with the IP address to connect to your backend deployed in local from a real iPhone
        // Use localhost to connect from the Simulator
        // Check your local IP with this command in Terminal: 'ipconfig getifaddr en0'
        
    //    static let baseURL = "http://192.168.1.44:10000/"
        static let baseURL = "http://localhost:10000/"
        #else
        
        // This is the production URL to your backend.
        // REMEMBER TO ADD A SLASH '/' TO THE END
        static let baseURL = "https://YOUR_HOSTING_URL/"
        #endif
        
        // Auth key generated with the script 'secret_generator.js'
        // It also needs to be configured in the backend side
        static let authKey = "YOUR_SECRET_KEY"
        // Identifier that is sent within a HTTP header in order to check in the backend which app is making the request
        // You can change it but mind changing it as well in the backend side.
        static let appIdentifier = "wrapfast"
        
        //Time out and delay time to retry http requests
        static let requestTimeout: TimeInterval = 180
        static let retryDelay: UInt32 = 2
    }
    
    enum AIProxy {
        static let partialKey = "<the-partial-key-from-the-dashboard>"
    }
    
    enum DeveloperInfo {
        static let name = "Form Fighter"
        static let contactEmail = "Julian@form-fighter.com"
        static let twitterUrl = URL(string: "https://x.com/JawnyJDevs")
    }
    
    // The amount of free credits you want to offer to try the app
    static let freeCredits = 5
    
    // Fill the App Store ID once you have created it in the App Store Connect.
    static let appStoreAppId = "YOUR_APP_STORE_APP_ID"
    
    // The confirmation word the user has to type in order to confirm account deletion
    static let deleteUserWordConfirmation = "delete"
    
    // Values to resize the images taken in order to reduce its size to store them.
    static let imageCompressionQuality = 0.2
    static let imageMaxDimension: CGFloat = 700
    
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "My App"
    }
    
    // This is a example of how you can embed a FAQ written in Markdown to display within a Text View.
    // We use it in the Settings View.
    // ChatGPT prompt to generate something similar:
    
    // You are an excellent marketing expert and product owner.
    //    
    //    I need your help to write a simple FAQ for my iOS app. Here is some context:
    //    - Name: WrapFast
    //    - Description: A nutrition app that analyzes with artificial intelligence images of meals taken by the user in order to estimate macronutrients.
    //    - Fact: There are estimations made by an AI.
    //    - Fact: It does not replace a professional nutritionist.
    //    - Fact: It can fail with certain images
    //    - Fact: Pictures can be imported from Photo Library or Camera
    //    - Fact: There is a free trial of certain number of tries.
    //    - Fact: There is a premium subscription to analyze unlimited meals.
    //    - Fact Analyze meals with AI requires too much computer power that is not free to us.
    //    - Contact information: email@email.com
    //
    //    Please write a simple FAQ for my app. Do not add or explain your reasoning. Answer:
    
    static let faqMarkdown: LocalizedStringKey = """
**Q: What is \(Const.appName)?**
A: \(Const.appName) is an AI-powered app that uses computer vision to give fighters real-time feedback on their punches, focusing on techniques like jabs and other strikes.

**Q: How does \(Const.appName) provide feedback on my form?**
A: The app utilizes advanced AI algorithms to analyze videos or images of your punches, comparing your technique against professional fighters to offer personalized insights.

**Q: Can \(Const.appName) replace a professional coach?**
A: No, \(Const.appName) is designed to complement your training by offering AI-driven feedback, but it cannot replace the expertise of a professional coach.

**Q: Why might the app fail to analyze some punches correctly?**
A: Punch analysis may be affected by factors such as poor lighting, unclear footage, or angles that prevent the AI from recognizing key body movements.

**Q: How can I import videos or images into \(Const.appName)?**
A: You can import videos or images directly from your Photo Library or record new ones using your device's Camera.


**Q: Who can I contact for support or feedback?**
A: For any support requests or feedback, please reach out to us at julian@form-fighter.com. We're here to help!
"""

}
