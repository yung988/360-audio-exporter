import SwiftUI

struct Export360View: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header & Info Block
            VStack(alignment: .leading, spacing: 8) {
                Text("360° video source")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Convert 360° camera files or equirectangular exports into modern formats, with stereo, original, or spatial audio intact.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !appState.inputVideos.isEmpty {
                    BatchInputQueueView()
                } else {
                    MediaDropZoneView(
                        title: "Drop up to 20 camera files or equirectangular videos here",
                        allowedExtensions: ["mp4", "mov", "360", "insv"],
                        mode: .export360Video
                    )
                }
            }
            
            // Export Configuration Grid
            if !appState.inputVideos.isEmpty {
                ExportSettingsView()
            } else {
                Spacer()
                    .frame(height: 120)
            }
            
            Spacer()
            
            // Footer (destination folder and action button)
            VStack(spacing: 12) {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack {
                    // Destination path selector
                    HStack(spacing: 8) {
                        Text("Export destination")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Text(appState.exportSettings.destinationFolder?.path ?? (!appState.inputVideos.isEmpty ? "Same folder as each source" : "Choose a folder..."))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.129, green: 0.137, blue: 0.149))
                            .cornerRadius(6)
                            .help(appState.exportSettings.destinationFolder?.path ?? "")
                        
                        Button("Choose...") {
                            if let folder = FileAccessService.selectDirectory() {
                                appState.exportSettings.destinationFolder = folder
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    // Export action
                    Button(action: {
                        appState.startExport()
                    }) {
                        Text(appState.inputVideos.count > 1 ? "Export \(appState.inputVideos.count) Videos" : "Start Export")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(appState.inputVideos.isEmpty ? Color.blue.opacity(0.4) : Color(red: 0.114, green: 0.380, blue: 0.882))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(appState.inputVideos.isEmpty)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}

private struct BatchInputQueueView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(appState.inputVideos.count) video\(appState.inputVideos.count == 1 ? "" : "s") queued")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Max \(AppState.maxBatchSize)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(5)

                Spacer()

                Button("Add Videos...") {
                    let urls = FileAccessService.selectFiles(
                        allowedExtensions: ["mp4", "mov", "360", "insv"],
                        limit: AppState.maxBatchSize - appState.inputVideos.count
                    )
                    Task {
                        await appState.probeAssets(urls: urls, mode: .export360Video, appendToBatch: true)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(appState.inputVideos.count >= AppState.maxBatchSize)

                Button("Clear") {
                    appState.clearInputVideos()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(Array(appState.inputVideos.enumerated()), id: \.element.id) { index, asset in
                        BatchInputRow(index: index + 1, asset: asset)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .background(Color(red: 0.129, green: 0.137, blue: 0.149))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct BatchInputRow: View {
    @EnvironmentObject var appState: AppState
    let index: Int
    let asset: MediaAsset

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .frame(width: 22, height: 22)
                .background(Color.black.opacity(0.22))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(asset.fileName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(asset.url.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .help(asset.url.path)
            }

            Spacer()

            if let probe = asset.probe {
                Text(queueSummary(for: probe))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Button {
                appState.removeInputVideo(id: asset.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.12))
        .cornerRadius(7)
    }

    private func queueSummary(for probe: MediaProbe) -> String {
        var parts: [String] = []
        if let width = probe.width, let height = probe.height {
            parts.append("\(width) × \(height)")
        }
        if let fps = probe.frameRate {
            parts.append(String(format: "%.2f fps", fps))
        }
        if let audio = probe.audioStreams.first {
            parts.append("\(audio.channels)ch \(audio.isLikelySpatial ? "ambisonic" : "audio")")
        }
        return parts.joined(separator: " · ")
    }
}
