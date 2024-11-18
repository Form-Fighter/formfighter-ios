import Foundation
import FirebaseCrashlytics

//MARK: - Example of use:
//Logger.log(message: "An error message", event: .error)
enum LogEvent: String {
    case error = "[‼️]"
    case info = "[ℹ️]"
    case debug = "[💬]"
    case verbose = "[🔬]"
    case warning = "[⚠️]"
    case severe = "[🔥]"
    case trace = "[🧐]"
    case connections = "[✅]"
}

class Logger {
    static var dateFormat = "hh:mm:ss"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    // Add a static property to control logging
    static var isLoggingEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    class func log(message: String, event: LogEvent, fileName: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("\(event.rawValue)[\(sourceFileName(filePath: fileName))]:\(line) -> \(message)")
            
            // Also log to Crashlytics if it's an error
            if event == .error {
                Crashlytics.crashlytics().log("\(event.rawValue) \(message)")
            }
        }
    }
    
    // Add new method to log non-fatal errors to Crashlytics
    static func recordError(_ error: Error, context: [String: Any]? = nil) {
        Crashlytics.crashlytics().record(error: error, userInfo: context)
        var params = context
        params["error_description"] = error.localizedDescription
        
        Analytics.logEvent("app_error", parameters: params)
        // Also log to Analytics
        Tracker.errorOccurred(
            domain: (error as NSError).domain,
            code: (error as NSError).code,
            description: error.localizedDescription
        )
    }
}

extension Date {
    func toString() -> String {
        return Logger.dateFormatter.string(from: self as Date)
    }
}
