import Foundation

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
    
    class func log(message: String, event: LogEvent, fileName: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function)  {
        
#if DEBUG
        print("\(event.rawValue)[\(sourceFileName(filePath: fileName))]:\(line) -> \(message)")
#endif
        
    }
}

extension Date {
    func toString() -> String {
        return Logger.dateFormatter.string(from: self as Date)
    }
}
