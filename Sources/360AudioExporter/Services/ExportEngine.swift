import Foundation

public protocol ExportEngine {
    func start(job: ExportJob, ffmpegPath: String) -> AsyncThrowingStream<ExportProgress, Error>
    func cancel()
}

public final class LiveExportEngine: ExportEngine {
    private let ffmpegService = FFmpegService()
    private let commandBuilder = FFmpegCommandBuilder()
    
    public init() {}
    
    public func cancel() {
        ffmpegService.cancel()
    }
    
    public func start(job: ExportJob, ffmpegPath: String) -> AsyncThrowingStream<ExportProgress, Error> {
        let args = commandBuilder.buildArguments(for: job)
        let totalDuration = getDuration(for: job)
        let startedAt = Date()
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    continuation.yield(ExportProgress(
                        percentage: 0,
                        currentTime: 0,
                        totalDuration: totalDuration,
                        stage: "Preparing",
                        message: "Preparing export...",
                        detail: commandBuilder.summary(for: job)
                    ))

                    let ffmpegStream = ffmpegService.run(arguments: args, ffmpegPath: ffmpegPath)
                    
                    for try await event in ffmpegStream {
                        switch event {
                        case .log(let logLine):
                            // Forward logs in progress message if needed for debugging or display
                            Logger.info("[ffmpeg] \(logLine)")
                            
                        case .progress(let currentTime, let speed):
                            var percentage: Double?
                            var eta: Double?
                            if let total = totalDuration, total > 0 {
                                percentage = min(0.99, currentTime / total) // Cap at 99% until completed
                                if currentTime > 0 {
                                    let elapsed = Date().timeIntervalSince(startedAt)
                                    eta = max(0, elapsed * ((total - currentTime) / currentTime))
                                }
                            }
                            
                            let progress = ExportProgress(
                                percentage: percentage,
                                currentTime: currentTime,
                                totalDuration: totalDuration,
                                estimatedRemainingSeconds: eta,
                                speed: speed,
                                stage: job.mode == .attachSpatialAudio ? "Merging streams" : "Encoding video",
                                message: job.mode == .attachSpatialAudio ? "Transferring audio track..." : "Exporting 360° video...",
                                detail: commandBuilder.summary(for: job)
                            )
                            continuation.yield(progress)
                        }
                    }
                    
                    // Finished successfully
                    let completedProgress = ExportProgress(
                        percentage: 1.0,
                        currentTime: totalDuration,
                        totalDuration: totalDuration,
                        estimatedRemainingSeconds: 0,
                        speed: nil,
                        stage: "Finishing",
                        message: "Done"
                    )
                    continuation.yield(completedProgress)
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func getDuration(for job: ExportJob) -> Double? {
        switch job.mode {
        case .export360Video:
            return job.inputVideo.probe?.duration
        case .attachSpatialAudio:
            // Take the shorter or longer depending on shortest flag.
            // Usually the video duration is the primary timeline anchor.
            return job.inputVideo.probe?.duration
        }
    }
}
