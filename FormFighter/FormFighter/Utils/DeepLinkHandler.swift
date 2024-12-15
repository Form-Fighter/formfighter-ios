import Foundation

enum DeepLinkType {
    case challenge(id: String, referrer: String?)
    case coach(id: String)
    case affiliate(code: String)
    case feedback(id: String)
}

class DeepLinkHandler {
    static func handle(url: URL) -> DeepLinkType? {
        print("🔗 Processing deep link: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Failed to create URL components from: \(url)")
            return nil
        }
        
        print("📍 URL Components:")
        print("- Scheme: \(components.scheme ?? "nil")")
        print("- Host: \(components.host ?? "nil")")
        print("- Path: \(components.path)")
        print("- Query Items: \(components.queryItems?.description ?? "nil")")
        
        guard let host = components.host else {
            print("❌ No host found in URL")
            return nil
        }
        
        let queryItems = components.queryItems ?? []
        
        switch host {
        case "challenge":
            let id = queryItems.first(where: { $0.name == "id" })?.value
            let referrer = queryItems.first(where: { $0.name == "referrer" })?.value
            
            print("🎯 Challenge deep link:")
            print("- ID: \(id ?? "nil")")
            print("- Referrer: \(referrer ?? "nil")")
            
            if let id = id {
                return .challenge(id: id, referrer: referrer)
            }
            
        case "join":
            print("🤝 Join deep link:")
            
            if let coachId = queryItems.first(where: { $0.name == "coachId" })?.value {
                print("- Coach ID: \(coachId)")
                return .coach(id: coachId)
            }
            
            if let affiliateCode = queryItems.first(where: { $0.name == "affiliateCode" })?.value {
                print("- Affiliate Code: \(affiliateCode)")
                return .affiliate(code: affiliateCode)
            }
            
            print("❌ No valid parameters found in join link")
            
        default:
            print("❌ Unknown deep link host: \(host)")
        }
        
        return nil
    }
} 