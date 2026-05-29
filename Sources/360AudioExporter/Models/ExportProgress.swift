import Foundation

public struct ExportProgress: Codable, Hashable {
    public var percentage: Double? // 0.0 to 1.0
    public var currentTime: Double? // in seconds
    public var totalDuration: Double? // in seconds
    public var estimatedRemainingSeconds: Double?
    public var speed: String? // e.g. "1.42x"
    public var stage: String
    public var message: String
    public var detail: String?
    
    public init(
        percentage: Double? = nil,
        currentTime: Double? = nil,
        totalDuration: Double? = nil,
        estimatedRemainingSeconds: Double? = nil,
        speed: String? = nil,
        stage: String = "Příprava",
        message: String = "",
        detail: String? = nil
    ) {
        self.percentage = percentage
        self.currentTime = currentTime
        self.totalDuration = totalDuration
        self.estimatedRemainingSeconds = estimatedRemainingSeconds
        self.speed = speed
        self.stage = stage
        self.message = message
        self.detail = detail
    }
}
