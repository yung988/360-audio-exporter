import Foundation

public struct Logger {
    public static func info(_ message: String) {
        print("[INFO] [\(currentTimestamp())] \(message)")
    }
    
    public static func error(_ message: String) {
        print("[ERROR] [\(currentTimestamp())] \(message)")
    }
    
    private static func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
