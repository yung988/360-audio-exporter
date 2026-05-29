import Foundation

public protocol ExportEngine {
    func start(job: ExportJob, ffmpegPath: String) -> AsyncThrowingStream<ExportProgress, Error>
    func cancel()
}

public final class LiveExportEngine: ExportEngine {
    private let ffmpegService = FFmpegService()
    
    public init() {}
    
    public func cancel() {
        ffmpegService.cancel()
    }
    
    public func start(job: ExportJob, ffmpegPath: String) -> AsyncThrowingStream<ExportProgress, Error> {
        let args = buildArguments(for: job)
        let totalDuration = getDuration(for: job)
        let startedAt = Date()
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    continuation.yield(ExportProgress(
                        percentage: 0,
                        currentTime: 0,
                        totalDuration: totalDuration,
                        stage: "Příprava",
                        message: "Sestavuji export...",
                        detail: commandSummary(for: job)
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
                                stage: job.mode == .attachSpatialAudio ? "Slučování streamů" : "Kódování videa",
                                message: job.mode == .attachSpatialAudio ? "Přidávám prostorové audio..." : "Exportuji 360° video...",
                                detail: commandSummary(for: job)
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
                        stage: "Dokončení",
                        message: "Dokončeno"
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
    
    private func buildArguments(for job: ExportJob) -> [String] {
        var args: [String] = ["-y"]
        
        switch job.mode {
        case .export360Video:
            // Input
            args.append(contentsOf: ["-i", job.inputVideo.url.path])
            
            // Video mapping
            args.append(contentsOf: ["-map", "0:v:0"])
            
            // Audio mapping if present
            let hasAudio = !(job.inputVideo.probe?.audioStreams.isEmpty ?? true)
            if hasAudio && job.settings.audioMode != .noAudio {
                args.append(contentsOf: ["-map", "0:a:0"])
            }
            
            let videoCodec = effectiveVideoCodec(for: job.settings)

            // Video filters (scaling)
            if let size = job.settings.effectiveResolution, videoCodec != .copy {
                args.append(contentsOf: ["-vf", "scale=\(size.width):\(size.height)"])
            }
            
            // Video codec
            switch videoCodec {
            case .copy:
                args.append(contentsOf: ["-c:v", "copy"])
            case .h264VideoToolbox:
                args.append(contentsOf: ["-c:v", "h264_videotoolbox"])
                args.append(contentsOf: ["-b:v", job.settings.effectiveVideoBitrate])
            case .hevcVideoToolbox:
                args.append(contentsOf: ["-c:v", "hevc_videotoolbox", "-tag:v", "hvc1"])
                args.append(contentsOf: ["-b:v", job.settings.effectiveVideoBitrate])
            case .proRes:
                args.append(contentsOf: ["-c:v", "prores", "-profile:v", "2"]) // ProRes 422 Standard
            case .vp9:
                args.append(contentsOf: ["-c:v", "libvpx-vp9", "-b:v", job.settings.effectiveVideoBitrate])
            }
            
            // Frame rate
            if let targetFps = job.settings.frameRateMode.doubleValue {
                args.append(contentsOf: ["-r", String(targetFps)])
            }
            
            // Audio codec
            if job.settings.audioMode == .noAudio {
                args.append("-an")
            } else {
                switch job.settings.audioMode {
                case .keepOriginal:
                    args.append(contentsOf: ["-c:a", "copy"])
                case .stereoAAC:
                    if job.settings.outputFormat == .webm {
                        args.append(contentsOf: ["-c:a", "libopus", "-ac", "2", "-b:a", "256k"])
                    } else {
                        args.append(contentsOf: ["-c:a", "aac", "-ac", "2", "-b:a", "256k"])
                    }
                case .spatialFourChannelAAC:
                    let codec = job.settings.outputFormat == .webm ? "libopus" : "aac"
                    args.append(contentsOf: ["-c:a", codec, "-ac", "4", "-b:a", "\(job.settings.audioBitrate)k"])
                case .noAudio:
                    break
                }
            }
            
            // Metadata & flags
            args.append(contentsOf: ["-map_metadata", "0"])
            if job.settings.outputFormat.supportsFastStart {
                args.append(contentsOf: ["-movflags", "+faststart"])
            }
            
            // Output
            args.append(job.outputURL.path)
            
        case .attachSpatialAudio:
            guard let secondary = job.secondarySource else {
                // Fallback (should not occur if UI validation is correct)
                args.append(contentsOf: ["-i", job.inputVideo.url.path])
                args.append(job.outputURL.path)
                return args
            }
            
            // Input 0: Final Video
            args.append(contentsOf: ["-i", job.inputVideo.url.path])
            // Input 1: Spatial Audio source
            args.append(contentsOf: ["-i", secondary.url.path])
            
            // Map video from first input
            args.append(contentsOf: ["-map", "0:v:0"])
            
            let spatialAudioMap = preferredSpatialAudioMap(for: secondary)

            // Map audio tracks based on attach mode
            switch job.attachAudioMode {
            case .replace:
                // Map audio from second input only
                args.append(contentsOf: ["-map", spatialAudioMap])
                
            case .add:
                // Map existing video's audio (if any) and then map spatial audio
                let hasVideoAudio = !(job.inputVideo.probe?.audioStreams.isEmpty ?? true)
                if hasVideoAudio {
                    args.append(contentsOf: ["-map", "0:a:0"])
                }
                args.append(contentsOf: ["-map", spatialAudioMap])
                
            case .keepStereoAndAddSpatial:
                // Map first audio from video (stereo), then map spatial audio
                let hasVideoAudio = !(job.inputVideo.probe?.audioStreams.isEmpty ?? true)
                if hasVideoAudio {
                    args.append(contentsOf: ["-map", "0:a:0"])
                }
                args.append(contentsOf: ["-map", spatialAudioMap])
            }
            
            // Video is always copied in this mode
            args.append(contentsOf: ["-c:v", "copy"])
            
            // Audio mapping configuration
            let isWav = secondary.url.pathExtension.lowercased() == "wav"
            let secondaryHasPcm = secondary.probe?.audioStreams.first?.codec.lowercased().contains("pcm") ?? false
            
            // If the audio source is WAV or uncompressed PCM, we must encode it to AAC 4-channel to be valid in MP4
            if isWav || secondaryHasPcm || job.settings.audioMode == .spatialFourChannelAAC || job.settings.outputFormat == .webm {
                // Determine layout mapping
                let channelCount = secondary.probe?.audioStreams.first?.channels ?? 4
                // Force aac and 4-channel mapping for spatial tracks
                let codec = job.settings.outputFormat == .webm ? "libopus" : "aac"
                args.append(contentsOf: ["-c:a", codec, "-ac", String(channelCount), "-b:a", "\(job.settings.audioBitrate)k"])
            } else {
                // If it is already a compressed format (AAC/Opus) and we want to preserve it
                args.append(contentsOf: ["-c:a", "copy"])
            }
            
            args.append(contentsOf: ["-map_metadata", "0"])
            args.append("-shortest")
            if job.settings.outputFormat.supportsFastStart {
                args.append(contentsOf: ["-movflags", "+faststart"])
            }
            
            // Output
            args.append(job.outputURL.path)
        }
        
        return args
    }

    private func commandSummary(for job: ExportJob) -> String {
        switch job.mode {
        case .export360Video:
            let resolution = job.settings.effectiveResolution.map { "\($0.width) x \($0.height)" } ?? "původní rozlišení"
            return "Video: \(job.settings.videoCodec.label), \(resolution), \(job.settings.effectiveVideoBitrate). Audio: \(job.settings.audioMode.label)."
        case .attachSpatialAudio:
            return "Video se kopíruje beze změny. Audio zdroj: \(job.secondarySource?.fileName ?? "neznámý soubor")."
        }
    }

    private func effectiveVideoCodec(for settings: ExportSettings) -> VideoCodec {
        if settings.outputFormat == .webm && settings.videoCodec != .copy {
            return .vp9
        }
        return settings.videoCodec
    }

    private func preferredSpatialAudioMap(for asset: MediaAsset) -> String {
        guard let streams = asset.probe?.audioStreams, !streams.isEmpty else {
            return "1:a:0"
        }

        let audioOrdinal = streams.firstIndex { $0.isLikelySpatial } ?? 0
        return "1:a:\(audioOrdinal)"
    }
}
