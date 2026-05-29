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
            warnings.append("Pozor: výstupní audio nemá 4 kanály (obsahuje: \(channels)ch). Pravděpodobně došlo k downmixu na stereo.")
        }
        
        // 2. Spherical metadata warning
        let expects360 = expectedJob.mode == .export360Video && expectedJob.inputVideo.fileType == .video360
        if expects360 && !projectionOk {
            warnings.append("Pozor: video může být 360°, ale soubor nemá spherical metadata. Některé přehrávače ho nemusí otevřít jako VR video.")
        }
        
        // 3. Duration mismatch
        if !durationOk && expectedJob.inputVideo.probe?.duration != nil {
            warnings.append("Pozor: délka výstupního souboru neodpovídá zdroji.")
        }
        
        let message = warnings.isEmpty ? "Výstup vytvořen úspěšně a je plně validní." : "Výstup byl vytvořen s varováním."
        
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
