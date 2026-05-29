import Foundation

public struct ValidationResult: Codable, Hashable {
    public let videoOk: Bool
    public let projectionOk: Bool
    public let channels: Int
    public let codec: String
    public let durationOk: Bool
    public let message: String
    public let warnings: [String]
    
    public var hasWarnings: Bool { !warnings.isEmpty }
    
    public init(videoOk: Bool, projectionOk: Bool, channels: Int, codec: String, durationOk: Bool, message: String, warnings: [String]) {
        self.videoOk = videoOk
        self.projectionOk = projectionOk
        self.channels = channels
        self.codec = codec
        self.durationOk = durationOk
        self.message = message
        self.warnings = warnings
    }
}

public final class MetadataService {
    private let ffprobeService: MediaProbeService
    
    public init(ffprobeService: MediaProbeService = FFprobeService()) {
        self.ffprobeService = ffprobeService
    }
    
    public func validate(url: URL, expectedJob: ExportJob, ffprobePath: String) async throws -> ValidationResult {
        let probe = try await ffprobeService.probe(url: url, ffprobePath: ffprobePath)
        
        let videoOk = !probe.videoStreams.isEmpty
        let projectionOk = probe.isLikely360
        let spatialAudio = probe.audioStreams.first { $0.channels >= 4 }
        let primaryAudio = spatialAudio ?? probe.audioStreams.first
        let channels = primaryAudio?.channels ?? 0
        let codec = primaryAudio?.codec ?? "N/A"
        var durationOk = false
        
        if let outputDur = probe.duration, let inputDur = expectedJob.inputVideo.probe?.duration {
            // Check if duration matches within 1.0 second tolerance
            durationOk = abs(outputDur - inputDur) < 1.0
        } else if probe.duration != nil {
            durationOk = true
        }
        
        var warnings: [String] = []
        
        // 1. Audio channels warning
        let expectsSpatial = expectedJob.mode == .attachSpatialAudio || expectedJob.settings.audioMode == .spatialFourChannelAAC
        if expectsSpatial && spatialAudio == nil {
            warnings.append("The exported audio is not 4-channel ambisonic audio. It contains \(channels) channel(s), so it may have been downmixed to stereo.")
        }
        
        // 2. Spherical metadata warning
        let expects360 = expectedJob.mode == .export360Video && expectedJob.inputVideo.fileType == .video360
        if expects360 && !projectionOk {
            warnings.append("The video looks like 360° footage, but spherical metadata was not found. Some players may not open it as VR video.")
        }
        
        // 3. Duration mismatch
        if !durationOk && expectedJob.inputVideo.probe?.duration != nil {
            warnings.append("The exported duration does not match the source file.")
        }
        
        let message = warnings.isEmpty ? "The export is complete and the file passed validation." : "The export is complete, but validation found warnings."
        
        return ValidationResult(
            videoOk: videoOk,
            projectionOk: projectionOk,
            channels: channels,
            codec: codec,
            durationOk: durationOk,
            message: message,
            warnings: warnings
        )
    }
}
