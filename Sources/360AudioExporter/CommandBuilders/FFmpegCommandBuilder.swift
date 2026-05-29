import Foundation

public struct FFmpegCommandBuilder {
    public init() {}

    public func buildArguments(for job: ExportJob) -> [String] {
        var args: [String] = ["-y"]

        switch job.mode {
        case .export360Video:
            args.append(contentsOf: ["-i", job.inputVideo.url.path])
            args.append(contentsOf: ["-map", "0:v:0"])

            let hasAudio = !(job.inputVideo.probe?.audioStreams.isEmpty ?? true)
            if hasAudio && job.settings.audioMode != .noAudio {
                args.append(contentsOf: ["-map", "0:a:0"])
            }

            let videoCodec = effectiveVideoCodec(for: job.settings)
            if let size = job.settings.effectiveResolution, videoCodec != .copy {
                args.append(contentsOf: ["-vf", "scale=\(size.width):\(size.height)"])
            }

            appendVideoCodec(videoCodec, settings: job.settings, to: &args)

            if let targetFps = job.settings.frameRateMode.doubleValue {
                args.append(contentsOf: ["-r", String(targetFps)])
            }

            appendAudioCodec(settings: job.settings, to: &args)
            args.append(contentsOf: ["-map_metadata", "0"])
            appendFastStartIfSupported(format: job.settings.outputFormat, to: &args)
            args.append(job.outputURL.path)

        case .attachSpatialAudio:
            guard let secondary = job.secondarySource else {
                args.append(contentsOf: ["-i", job.inputVideo.url.path, job.outputURL.path])
                return args
            }

            args.append(contentsOf: ["-i", job.inputVideo.url.path])
            args.append(contentsOf: ["-i", secondary.url.path])
            args.append(contentsOf: ["-map", "0:v:0"])

            let spatialAudioMap = preferredSpatialAudioMap(for: secondary)
            switch job.attachAudioMode {
            case .replace:
                args.append(contentsOf: ["-map", spatialAudioMap])
            case .add:
                if !(job.inputVideo.probe?.audioStreams.isEmpty ?? true) {
                    args.append(contentsOf: ["-map", "0:a:0"])
                }
                args.append(contentsOf: ["-map", spatialAudioMap])
            case .keepStereoAndAddSpatial:
                if !(job.inputVideo.probe?.audioStreams.isEmpty ?? true) {
                    args.append(contentsOf: ["-map", "0:a:0"])
                }
                args.append(contentsOf: ["-map", spatialAudioMap])
            }

            args.append(contentsOf: ["-c:v", "copy"])
            appendAttachAudioCodec(job: job, secondary: secondary, to: &args)
            args.append(contentsOf: ["-map_metadata", "0"])
            args.append("-shortest")
            appendFastStartIfSupported(format: job.settings.outputFormat, to: &args)
            args.append(job.outputURL.path)
        }

        return args
    }

    public func commandLine(for job: ExportJob, ffmpegPath: String = "ffmpeg") -> String {
        ([ffmpegPath] + buildArguments(for: job)).map(Self.shellEscaped).joined(separator: " ")
    }

    public func summary(for job: ExportJob) -> String {
        switch job.mode {
        case .export360Video:
            let codec = effectiveVideoCodec(for: job.settings)
            let resolution = job.settings.effectiveResolution.map { "\($0.width) x \($0.height)" } ?? "původní rozlišení"
            return "Video: \(codec.label), \(resolution), \(job.settings.effectiveVideoBitrate). Audio: \(job.settings.audioMode.label)."
        case .attachSpatialAudio:
            return "Video se kopíruje beze změny. Audio zdroj: \(job.secondarySource?.fileName ?? "neznámý soubor")."
        }
    }

    public func preferredSpatialAudioMap(for asset: MediaAsset) -> String {
        guard let streams = asset.probe?.audioStreams, !streams.isEmpty else {
            return "1:a:0"
        }

        let audioOrdinal = streams.firstIndex { $0.isLikelySpatial } ?? 0
        return "1:a:\(audioOrdinal)"
    }

    private func effectiveVideoCodec(for settings: ExportSettings) -> VideoCodec {
        if settings.outputFormat == .webm && settings.videoCodec != .copy {
            return .vp9
        }
        return settings.videoCodec
    }

    private func appendVideoCodec(_ codec: VideoCodec, settings: ExportSettings, to args: inout [String]) {
        switch codec {
        case .copy:
            args.append(contentsOf: ["-c:v", "copy"])
        case .h264VideoToolbox:
            args.append(contentsOf: ["-c:v", "h264_videotoolbox", "-b:v", settings.effectiveVideoBitrate])
        case .hevcVideoToolbox:
            args.append(contentsOf: ["-c:v", "hevc_videotoolbox", "-tag:v", "hvc1", "-b:v", settings.effectiveVideoBitrate])
        case .proRes:
            args.append(contentsOf: ["-c:v", "prores", "-profile:v", "2"])
        case .vp9:
            args.append(contentsOf: ["-c:v", "libvpx-vp9", "-b:v", settings.effectiveVideoBitrate])
        }
    }

    private func appendAudioCodec(settings: ExportSettings, to args: inout [String]) {
        switch settings.audioMode {
        case .noAudio:
            args.append("-an")
        case .keepOriginal:
            args.append(contentsOf: ["-c:a", "copy"])
        case .stereoAAC:
            let codec = settings.outputFormat == .webm ? "libopus" : "aac"
            args.append(contentsOf: ["-c:a", codec, "-ac", "2", "-b:a", "256k"])
        case .spatialFourChannelAAC:
            let codec = settings.outputFormat == .webm ? "libopus" : "aac"
            args.append(contentsOf: ["-c:a", codec, "-ac", "4", "-b:a", "\(settings.audioBitrate)k"])
        }
    }

    private func appendAttachAudioCodec(job: ExportJob, secondary: MediaAsset, to args: inout [String]) {
        let spatialStream = secondary.probe?.audioStreams.first { $0.isLikelySpatial }
        let sourceStream = spatialStream ?? secondary.probe?.audioStreams.first
        let isWav = secondary.url.pathExtension.lowercased() == "wav"
        let hasPcm = sourceStream?.codec.lowercased().contains("pcm") ?? false

        if isWav || hasPcm || job.settings.audioMode == .spatialFourChannelAAC || job.settings.outputFormat == .webm {
            let channelCount = sourceStream?.channels ?? 4
            let codec = job.settings.outputFormat == .webm ? "libopus" : "aac"
            args.append(contentsOf: ["-c:a", codec, "-ac", String(channelCount), "-b:a", "\(job.settings.audioBitrate)k"])
        } else {
            args.append(contentsOf: ["-c:a", "copy"])
        }
    }

    private func appendFastStartIfSupported(format: OutputFormat, to args: inout [String]) {
        if format.supportsFastStart {
            args.append(contentsOf: ["-movflags", "+faststart"])
        }
    }

    private static func shellEscaped(_ value: String) -> String {
        guard !value.isEmpty else { return "''" }
        let safeCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_./:-+=,%"))
        if value.unicodeScalars.allSatisfy({ safeCharacters.contains($0) }) {
            return value
        }
        return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
