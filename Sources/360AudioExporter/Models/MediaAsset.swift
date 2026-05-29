import Foundation

public enum MediaFileType: String, Codable, CaseIterable {
    case video360 = "360° Video"
    case normalVideo = "Standard Video"
    case audio = "Audio"
    case unknown = "Unknown"
}

public struct MediaAsset: Identifiable, Hashable, Codable {
    public let id: UUID
    public let url: URL
    public var fileName: String
    public var fileType: MediaFileType
    public var probe: MediaProbe?
    
    public init(id: UUID = UUID(), url: URL, fileName: String, fileType: MediaFileType, probe: MediaProbe? = nil) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.fileType = fileType
        self.probe = probe
    }
}
