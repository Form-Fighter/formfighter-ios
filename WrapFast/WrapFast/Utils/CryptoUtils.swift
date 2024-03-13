import Foundation
import CryptoKit

class CryptoUtils {
    private init(){}
    static let shared = CryptoUtils()
    
    func createHmac(key: String, phrase: String) -> String {
        let key = SymmetricKey(data: Data(key.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(phrase.utf8), using: key)
        
        return Data(signature).map { String(format: "%02hhx", $0) }.joined()
    }
}
