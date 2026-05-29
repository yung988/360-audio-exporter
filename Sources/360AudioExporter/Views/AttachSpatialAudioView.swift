import SwiftUI

struct AttachSpatialAudioView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. Rendered Video Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Finished 360° export")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Choose the finished video you want to keep, for example an 8K export. Orbit 360 copies the video stream unchanged and only updates the audio.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let asset = appState.renderedVideo {
                    MediaInfoCardView(
                        asset: asset,
                        mode: .attachSpatialAudio,
                        isSecondary: false,
                        allowedExtensions: ["mp4", "mov"]
                    )
                } else {
                    MediaDropZoneView(
                        title: "Drop the finished 360° export you want to keep",
                        allowedExtensions: ["mp4", "mov"],
                        mode: .attachSpatialAudio,
                        isSecondary: false
                    )
                }
            }
            
            // 2. Audio Source Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Audio source file")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Choose the original camera file, WAV, AAC, or video source that contains the audio track you want to transfer.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let asset = appState.spatialAudioSource {
                    MediaInfoCardView(
                        asset: asset,
                        mode: .attachSpatialAudio,
                        isSecondary: true,
                        allowedExtensions: ["wav", "mp4", "mov", "360", "insv", "m4a", "aac"]
                    )
                } else {
                    MediaDropZoneView(
                        title: "Drop the source file containing the audio track",
                        allowedExtensions: ["wav", "mp4", "mov", "360", "insv", "m4a", "aac"],
                        mode: .attachSpatialAudio,
                        isSecondary: true
                    )
                }
            }
            
            // 3. Audio mapping and copy options
            if appState.renderedVideo != nil && appState.spatialAudioSource != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Audio replacement settings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Output format")
                                    .font(.caption2)
                                    .foregroundColor(.gray)

                                Picker("", selection: $appState.exportSettings.outputFormat) {
                                    ForEach(OutputFormat.allCases) { format in
                                        Text(format.label).tag(format)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .labelsHidden()
                            }

                            // Audio merge mode picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Audio track mode")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Picker("", selection: $appState.attachAudioMode) {
                                    ForEach(AttachAudioMode.allCases) { mode in
                                        Text(mode.label).tag(mode)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .labelsHidden()
                            }
                            
                            // Audio encoding bitrate picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Audio bitrate")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Picker("", selection: $appState.exportSettings.audioBitrate) {
                                    Text("768 kbps").tag(768)
                                    Text("512 kbps").tag(512)
                                    Text("320 kbps").tag(320)
                                    Text("256 kbps").tag(256)
                                    Text("128 kbps").tag(128)
                                }
                                .pickerStyle(MenuPickerStyle())
                                .labelsHidden()
                            }
                        }
                        .padding(12)
                        .background(Color(red: 0.129, green: 0.137, blue: 0.149))
                        .cornerRadius(10)
                        
                        // Technical warning/info card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("What this mode does")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            Text("• Your finished video is copied 1:1, so an 8K export is not re-encoded.\n• Existing audio tracks can be replaced, kept, or paired with the new track.\n• Existing 360° projection metadata is preserved.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .lineSpacing(3)

                            if let audio = appState.spatialAudioSource?.probe?.audioStreams.first {
                                Text("Selected audio track: #\(audio.index), \(audio.channels)ch, \(audio.codec)\(audio.isLikelySpatial ? " (spatial)" : "")")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("No audio track was found. Validation will check the result once processed.")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.129, green: 0.137, blue: 0.149))
                        .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 12) {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack {
                    // Destination path selector
                    HStack(spacing: 8) {
                        Text("Export destination")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Text(appState.exportSettings.destinationFolder?.path ?? (appState.renderedVideo != nil ? "Same folder as video" : "Choose a folder..."))
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
                    
                    // Action button
                    Button(action: {
                        appState.startExport()
                    }) {
                        Text("Transfer Audio")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(appState.renderedVideo == nil || appState.spatialAudioSource == nil ? Color.blue.opacity(0.4) : Color(red: 0.114, green: 0.380, blue: 0.882))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(appState.renderedVideo == nil || appState.spatialAudioSource == nil)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}
