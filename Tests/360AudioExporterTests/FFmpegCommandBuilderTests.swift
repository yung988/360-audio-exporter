import Foundation
import Testing
@testable import Orbit360

struct FFmpegCommandBuilderTests {
    @Test func export360UsesCustomResolutionAndBitrate() {
        var settings = ExportSettings.default
        settings.outputFormat = .mp4
        settings.videoCodec = .hevcVideoToolbox
        settings.resolution = .custom
        settings.customWidth = 4096
        settings.customHeight = 2048
        settings.qualityPreset = .custom
        settings.customVideoBitrateMbps = 55

        let asset = videoAsset(path: "/tmp/source video.mp4")
        let job = ExportJob(
            mode: .export360Video,
            inputVideo: asset,
            settings: settings,
            outputURL: URL(fileURLWithPath: "/tmp/output.mp4")
        )

        let args = FFmpegCommandBuilder().buildArguments(for: job)

        #expect(args.contains("scale=4096:2048"))
        #expect(containsPair("-b:v", "55M", in: args))
        #expect(containsPair("-c:v", "hevc_videotoolbox", in: args))
        #expect(containsPair("-movflags", "+faststart", in: args))
    }

    @Test func webMForcesVp9AndOpus() {
        var settings = ExportSettings.default
        settings.outputFormat = .webm
        settings.videoCodec = .hevcVideoToolbox
        settings.audioMode = .spatialFourChannelAAC

        let job = ExportJob(
            mode: .export360Video,
            inputVideo: videoAsset(path: "/tmp/source.mp4"),
            settings: settings,
            outputURL: URL(fileURLWithPath: "/tmp/output.webm")
        )

        let args = FFmpegCommandBuilder().buildArguments(for: job)

        #expect(containsPair("-c:v", "libvpx-vp9", in: args))
        #expect(containsPair("-c:a", "libopus", in: args))
        #expect(!containsPair("-movflags", "+faststart", in: args))
    }

    @Test func attachSpatialPrefersFourChannelAudioOrdinal() {
        let rendered = videoAsset(path: "/tmp/rendered.mp4", audioStreams: [AudioStreamInfo(index: 1, codec: "aac", channels: 2, channelLayout: "stereo", sampleRate: 48_000, bitrate: 128_000)])
        let source = videoAsset(path: "/tmp/source.mov", audioStreams: [
            AudioStreamInfo(index: 1, codec: "aac", channels: 2, channelLayout: "stereo", sampleRate: 48_000, bitrate: 128_000),
            AudioStreamInfo(index: 2, codec: "aac", channels: 4, channelLayout: nil, sampleRate: 48_000, bitrate: 768_000)
        ])
        let job = ExportJob(
            mode: .attachSpatialAudio,
            inputVideo: rendered,
            secondarySource: source,
            settings: .default,
            attachAudioMode: .replace,
            outputURL: URL(fileURLWithPath: "/tmp/output.mp4")
        )

        let args = FFmpegCommandBuilder().buildArguments(for: job)

        #expect(containsPair("-map", "1:a:1", in: args))
    }

    private func videoAsset(path: String, audioStreams: [AudioStreamInfo] = [AudioStreamInfo(index: 1, codec: "aac", channels: 4, channelLayout: nil, sampleRate: 48_000, bitrate: 768_000)]) -> MediaAsset {
        let probe = MediaProbe(
            duration: 60,
            width: 3840,
            height: 1920,
            frameRate: 29.97,
            videoCodec: "hevc",
            audioStreams: audioStreams,
            videoStreams: [VideoStreamInfo(index: 0, codec: "hevc", width: 3840, height: 1920, frameRate: 29.97, bitrate: 40_000_000)],
            containerFormat: "mov,mp4,m4a,3gp,3g2,mj2",
            isLikely360: true
        )

        return MediaAsset(url: URL(fileURLWithPath: path), fileName: URL(fileURLWithPath: path).lastPathComponent, fileType: .video360, probe: probe)
    }

    private func containsPair(_ key: String, _ value: String, in args: [String]) -> Bool {
        args.indices.contains { index in
            index + 1 < args.count && args[index] == key && args[index + 1] == value
        }
    }
}
