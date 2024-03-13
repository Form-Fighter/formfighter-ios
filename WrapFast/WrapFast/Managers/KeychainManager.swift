import Foundation
import KeychainSwift

class KeychainManager {
    private init() {}
    private let keychain = KeychainSwift()
    static let shared = KeychainManager()
    
    // MARK: Use free credits functions if you want to offer some free requests
    // to let the user test your app and control when they are without credits to
    // present the Paywall.
    // We store the free credits in the Keychain to prevent abuse of them between new installations
    // because the Keychain values persists even the user uninstall the app.
    
    func storeInitialFreeExtraCredits() {
        Logger.log(message: "Storing \(Const.freeCredits) FREE CREDITS", event: .debug)
        keychain.set("\(Const.freeCredits)", forKey: Const.Keychain.freeCreditsKey)
    }
    
    func getFreeExtraCredits() -> Int {
        if let freeCreditsString = keychain.get(Const.Keychain.freeCreditsKey), let freeCredits = Int(freeCreditsString) {
            return freeCredits
        } else {
            return 0
        }
    }
    
    func existsStoredFreeCredits() -> Bool {
        if keychain.get(Const.Keychain.freeCreditsKey) != nil {
            return true
        } else {
            return false
        }
    }
    
    func setFreeCredits(with value: Int) {
        keychain.set(String(value), forKey: Const.Keychain.freeCreditsKey)
    }
}

// MARK: - DEBUG
extension KeychainManager {
    func deleteFreeExtraCredits() {
        keychain.delete(Const.Keychain.freeCreditsKey)
    }
    
    func deleteAuthToken() {
        keychain.delete(Const.Keychain.tokenKey)
    }
}
