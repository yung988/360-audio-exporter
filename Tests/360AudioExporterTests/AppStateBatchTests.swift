import Foundation
import Testing
@testable import Orbit360

@MainActor
struct AppStateBatchTests {
    @Test func probeAssetsQueuesAtMostTwentyVideos() async {
        let state = AppState(ffprobeService: MockProbeService())
        state.ffprobePath = "/bin/sh"

        let urls = (1...25).map { URL(fileURLWithPath: "/tmp/video-\($0).mp4") }
        await state.probeAssets(urls: urls, mode: .export360Video)

        #expect(state.inputVideos.count == AppState.maxBatchSize)
        #expect(state.inputVideos.first?.fileName == "video-1.mp4")
        #expect(state.inputVideos.last?.fileName == "video-20.mp4")
    }
}

private struct MockProbeService: MediaProbeService {
    func probe(url: URL, ffprobePath: String) async throws -> MediaProbe {
        MediaProbe(
            duration: 60,
            width: 3840,
            height: 1920,
            frameRate: 29.97,
            videoCodec: "hevc",
            audioStreams: [
                AudioStreamInfo(index: 1, codec: "aac", channels: 4, channelLayout: nil, sampleRate: 48_000, bitrate: 768_000)
            ],
            videoStreams: [
                VideoStreamInfo(index: 0, codec: "hevc", width: 3840, height: 1920, frameRate: 29.97, bitrate: 40_000_000)
            ],
            containerFormat: "mov,mp4,m4a,3gp,3g2,mj2",
            isLikely360: true
        )
    }
}
