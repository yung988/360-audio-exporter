import SwiftUI

struct MediaInfoCardView: View {
    @EnvironmentObject var appState: AppState
    let asset: MediaAsset
    let mode: ExportMode
    var isSecondary: Bool = false
    let allowedExtensions: [String]
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail / Icon representation
            ZStack(alignment: .topTrailing) {
                // Background representation
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 140, height: 95)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: asset.fileType == .audio ? "waveform" : "video")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                            Text(asset.fileType.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )
                
                // 360 Badge
                if asset.fileType == .video360 {
                    Text("360°")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .cornerRadius(4)
                        .padding(6)
                }
            }
            
            // Metadata columns
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(asset.fileName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(asset.url.path)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .help(asset.url.path)
                    }
                    
                    Spacer()
                    
                    Button("Změnit soubor...") {
                        if let selectedURL = FileAccessService.selectFile(allowedExtensions: allowedExtensions) {
                            Task {
                                await appState.probeAsset(url: selectedURL, mode: mode, isSecondary: isSecondary)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Detailed Technical Spec Grid
                if let probe = asset.probe {
                    let creationDateStr = getFileCreationDate(url: asset.url)
                    let fileSize = getFileSize(url: asset.url)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 16) {
                            // Date
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(creationDateStr)
                            }
                            
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                Text(TimecodeParser.format(seconds: probe.duration))
                            }
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "externaldrive")
                                    .foregroundColor(.gray)
                                Text(fileSize)
                            }

                            if let format = probe.containerFormat {
                                HStack(spacing: 4) {
                                    Image(systemName: "shippingbox")
                                        .foregroundColor(.gray)
                                    Text(format)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        HStack(spacing: 16) {
                            // Resolution
                            if let w = probe.width, let h = probe.height {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                        .foregroundColor(.gray)
                                    Text("\(w) × \(h)")
                                }
                            }
                            
                            // FPS
                            if let fps = probe.frameRate {
                                HStack(spacing: 4) {
                                    Image(systemName: "speedometer")
                                        .foregroundColor(.gray)
                                    Text(String(format: "%.2f fps", fps))
                                }
                            }
                        }
                        
                        // Audio info
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .foregroundColor(.gray)
                            if let audio = probe.audioStreams.first {
                                let layoutInfo = audio.channelLayout != nil ? " (\(audio.channelLayout!))" : ""
                                let spatialLabel = audio.isLikelySpatial ? "Spatial (Ambisonics)" : "Stereo"
                                Text("Audio: \(audio.channels)ch \(spatialLabel)\(layoutInfo) [\(audio.codec)]")
                            } else {
                                Text("Audio: Bez zvuku")
                            }
                        }

                        if !probe.videoStreams.isEmpty || !probe.audioStreams.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.vertical, 2)

                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(probe.videoStreams.prefix(2)) { stream in
                                    Text("Video stopa #\(stream.index): \(stream.codec), \(stream.width) × \(stream.height)\(stream.frameRate.map { String(format: ", %.2f fps", $0) } ?? "")")
                                        .lineLimit(1)
                                }

                                ForEach(probe.audioStreams.prefix(4)) { stream in
                                    Text("Audio stopa #\(stream.index): \(stream.channels)ch, \(stream.codec)\(stream.isLikelySpatial ? " - pravděpodobně spatial" : "")")
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
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
    
    private func getFileCreationDate(url: URL) -> String {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            if let date = attrs[.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "d. M. yyyy, HH:mm"
                return formatter.string(from: date)
            }
        } catch {}
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d. M. yyyy, HH:mm"
        return formatter.string(from: Date())
    }

    private func getFileSize(url: URL) -> String {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attrs[.size] as? NSNumber {
                return ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
            }
        } catch {}

        return "neznámá velikost"
    }
}
