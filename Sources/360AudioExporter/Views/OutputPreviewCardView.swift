import SwiftUI

struct OutputPreviewCardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output preview")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ZStack {
                VideoThumbnailView(
                    asset: previewAsset,
                    ffmpegPath: appState.ffmpegPath,
                    height: 160,
                    cornerRadius: 8
                ) {
                    SpherePlaceholderView()
                }
                
                Image(systemName: "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(outputSummary)
                    .font(.caption2)
                    .foregroundColor(.gray)

                if appState.exportSettings.outputFormat == .webm && appState.exportSettings.videoCodec != .vp9 && appState.exportSettings.videoCodec != .copy {
                    Text("WebM will automatically use VP9 + Opus.")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.129, green: 0.137, blue: 0.149))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private var outputSummary: String {
        let settings = appState.exportSettings
        let resolution = settings.effectiveResolution.map { "\($0.width) x \($0.height)" } ?? "source resolution"
        return "\(settings.outputFormat.label), \(resolution), \(settings.effectiveVideoBitrate), \(settings.audioMode.label)."
    }

    private var previewAsset: MediaAsset? {
        switch appState.selectedMode {
        case .export360Video:
            return appState.inputVideo
        case .attachSpatialAudio:
            return appState.renderedVideo
        }
    }
}

private struct SpherePlaceholderView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))

            Canvas { context, size in
                let w = size.width
                let h = size.height
                let cx = w / 2
                let cy = h / 2
                let r = min(w, h) * 0.4

                context.stroke(
                    Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                    with: .color(.gray.opacity(0.35)),
                    lineWidth: 1
                )

                for factor in [0.25, 0.5, 0.75] {
                    let ew = r * 2 * factor
                    context.stroke(
                        Path(ellipseIn: CGRect(x: cx - ew / 2, y: cy - r, width: ew, height: r * 2)),
                        with: .color(.gray.opacity(0.25)),
                        lineWidth: 1
                    )
                }

                for factor in [0.25, 0.5, 0.75] {
                    let eh = r * 2 * factor
                    context.stroke(
                        Path(ellipseIn: CGRect(x: cx - r, y: cy - eh / 2, width: r * 2, height: eh)),
                        with: .color(.gray.opacity(0.25)),
                        lineWidth: 1
                    )
                }

                var horizontalLine = Path()
                horizontalLine.move(to: CGPoint(x: cx - r, y: cy))
                horizontalLine.addLine(to: CGPoint(x: cx + r, y: cy))
                context.stroke(horizontalLine, with: .color(.gray.opacity(0.35)), lineWidth: 1)

                var verticalLine = Path()
                verticalLine.move(to: CGPoint(x: cx, y: cy - r))
                verticalLine.addLine(to: CGPoint(x: cx, y: cy + r))
                context.stroke(verticalLine, with: .color(.gray.opacity(0.35)), lineWidth: 1)
            }
        }
    }
}
