import Foundation

public struct TimecodeParser {
    public static func format(seconds: Double?) -> String {
        guard let seconds = seconds else { return "--:--" }
        let totalSecs = Int(round(seconds))
        let h = totalSecs / 3600
        let m = (totalSecs % 3600) / 60
        let s = totalSecs % 60
        
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    public static func formatDuration(seconds: Double?) -> String {
        guard let seconds = seconds else { return "neznámý" }
        let totalSecs = max(0, Int(round(seconds)))
        let h = totalSecs / 3600
        let m = (totalSecs % 3600) / 60
        let s = totalSecs % 60

        if h > 0 {
            return "\(h) h \(m) min"
        }
        if m > 0 {
            return "\(m) min \(s) s"
        }
        return "\(s) s"
    }
    
    public static func parse(timecode: String) -> Double? {
        let clean = timecode.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = clean.components(separatedBy: ":")
        guard parts.count >= 2 else { return nil }
        
        var h = 0.0
        var m = 0.0
        var s = 0.0
        
        if parts.count == 3 {
            h = Double(parts[0]) ?? 0.0
            m = Double(parts[1]) ?? 0.0
            s = Double(parts[2]) ?? 0.0
        } else if parts.count == 2 {
            m = Double(parts[0]) ?? 0.0
            s = Double(parts[1]) ?? 0.0
        }
        
        return (h * 3600.0) + (m * 60.0) + s
    }
}
