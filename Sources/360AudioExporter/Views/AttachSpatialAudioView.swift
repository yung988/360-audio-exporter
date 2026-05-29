import SwiftUI

struct AttachSpatialAudioView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. Rendered Video Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Hotové video (MP4 / MOV bez spatial audia)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let asset = appState.renderedVideo {
                    MediaInfoCardView(
                        asset: asset,
                        mode: .attachSpatialAudio,
                        isSecondary: false,
                        allowedExtensions: ["mp4", "mov"]
                    )
                } else {
                    MediaDropZoneView(
                        title: "Přetáhněte hotový video soubor sem",
                        allowedExtensions: ["mp4", "mov"],
                        mode: .attachSpatialAudio,
                        isSecondary: false
                    )
                }
            }
            
            // 2. Spatial Audio Source Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Zdroj prostorového audia (360 kamera, wav apod.)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let asset = appState.spatialAudioSource {
                    MediaInfoCardView(
                        asset: asset,
                        mode: .attachSpatialAudio,
                        isSecondary: true,
                        allowedExtensions: ["wav", "mp4", "mov", "360", "insv", "m4a", "aac"]
                    )
                } else {
                    MediaDropZoneView(
                        title: "Přetáhněte zdroj s prostorovým audiem sem",
                        allowedExtensions: ["wav", "mp4", "mov", "360", "insv", "m4a", "aac"],
                        mode: .attachSpatialAudio,
                        isSecondary: true
                    )
                }
            }
            
            // 3. Audio mapping and copy options
            if appState.renderedVideo != nil && appState.spatialAudioSource != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nastavení sloučení")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Výstupní formát")
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

                            // Režim sloučení picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Režim audio stop")
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
                                Text("Informace o převodu")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            Text("• Video se nebude překódovávat (kopíruje se 1:1 bez ztráty kvality).\n• Prostorové audio se zkopíruje přímo, nebo se překóduje na 4kanálové AAC (podle zdroje).\n• Původní metadata o 360° projekci videa budou zachována.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .lineSpacing(3)

                            if let audio = appState.spatialAudioSource?.probe?.audioStreams.first(where: { $0.isLikelySpatial }) {
                                Text("Vybraná spatial stopa: #\(audio.index), \(audio.channels)ch, \(audio.codec)")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("Ve zdroji zatím nevidím jasnou 4kanálovou stopu. Aplikace použije první audio stopu a validace výsledek zkontroluje.")
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
                    // Destination Path Selector
                    HStack(spacing: 8) {
                        Text("Cíl exportu")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Text(appState.exportSettings.destinationFolder?.path ?? (appState.renderedVideo != nil ? "Stejná složka jako video" : "Vyberte složku..."))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.129, green: 0.137, blue: 0.149))
                            .cornerRadius(6)
                            .help(appState.exportSettings.destinationFolder?.path ?? "")
                        
                        Button("Vybrat...") {
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
                        Text("Spustit sloučení")
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
