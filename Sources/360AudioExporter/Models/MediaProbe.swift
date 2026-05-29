import Foundation

public struct AudioStreamInfo: Identifiable, Hashable, Codable {
    public var id: Int { index }
    public let index: Int
    public let codec: String
    public let channels: Int
    public let channelLayout: String?
    public let sampleRate: Int?
    public let bitrate: Int?
    
    public var isLikelySpatial: Bool {
        return channels == 4 || (channelLayout?.lowercased().contains("ambisonic") == true)
    }
    
    public init(index: Int, codec: String, channels: Int, channelLayout: String?, sampleRate: Int?, bitrate: Int?) {
        self.index = index
        self.codec = codec
        self.channels = channels
        self.channelLayout = channelLayout
        self.sampleRate = sampleRate
        self.bitrate = bitrate
    }
}

public struct VideoStreamInfo: Identifiable, Hashable, Codable {
    public var id: Int { index }
    public let index: Int
    public let codec: String
    public let width: Int
    public let height: Int
    public let frameRate: Double?
    public let bitrate: Int?
    
    public init(index: Int, codec: String, width: Int, height: Int, frameRate: Double?, bitrate: Int?) {
        self.index = index
        self.codec = codec
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.bitrate = bitrate
    }
}

public struct MediaProbe: Hashable, Codable {
    public var duration: Double?
    public var width: Int?
    public var height: Int?
    public var frameRate: Double?
    public var videoCodec: String?
    public var audioStreams: [AudioStreamInfo]
    public var videoStreams: [VideoStreamInfo]
    public var containerFormat: String?
    public var isLikely360: Bool
    
    public init(
        duration: Double? = nil,
        width: Int? = nil,
        height: Int? = nil,
        frameRate: Double? = nil,
        videoCodec: String? = nil,
        audioStreams: [AudioStreamInfo] = [],
        videoStreams: [VideoStreamInfo] = [],
        containerFormat: String? = nil,
        isLikely360: Bool = false
    ) {
        self.duration = duration
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.videoCodec = videoCodec
        self.audioStreams = audioStreams
        self.videoStreams = videoStreams
        self.containerFormat = containerFormat
        self.isLikely360 = isLikely360
    }
}
