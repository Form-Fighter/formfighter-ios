import Foundation

extension String {
    var localized: String {
        return NSLocalizedString (self, comment: "")
    }
    
    var removeMarkdownJsonSyntax: String {
        var modifiedStr = self
        let jsonStartPattern = "^```json\\n?"
        let jsonEndPattern = "```$"
        
        if let startRange = modifiedStr.range(of: jsonStartPattern, options: [.regularExpression]) {
            modifiedStr.removeSubrange(startRange)
        }
        
        if let endRange = modifiedStr.range(of: jsonEndPattern, options: [.regularExpression]) {
            modifiedStr.removeSubrange(endRange)
        }
        
        return modifiedStr
    }
    
    var toAIProxyURL: URL? {
        URL(string: "data:image/jpeg;base64,\(self)")
    }
    
}
