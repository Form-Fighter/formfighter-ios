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
    
    // Convert total inches to feet & inches display format
    func heightFormatted() -> (feet: String, inches: String) {
        guard let totalInches = Int(self) else { return ("", "") }
        let feet = totalInches / 12
        let inches = totalInches % 12
        return (String(feet), String(inches))
    }
}

extension String {
    static let defaultHeight = "69"  // 5'9" in inches
    static let defaultWeight = "100" // 100 lbs
    
    // Convert feet & inches strings to total inches
    static func heightInTotalInches(feet: String, inches: String) -> String {
        guard let ft = Int(feet), let inch = Int(inches) else { return "" }
        let totalInches = (ft * 12) + inch
        return String(totalInches)
    }
}
