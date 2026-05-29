import SwiftUI

struct ExportSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nastavení exportu")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(alignment: .top, spacing: 16) {
                // Dropdown grids
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Output format
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Výstupní formát")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Picker("", selection: $appState.exportSettings.outputFormat) {
                                ForEach(OutputFormat.allCases) { item in
                                    Text(item.label).tag(item)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }

                        // Video codec
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Video kodek")
                                .font(.caption2)
                                .foregroundColor(.gray)

                            Picker("", selection: $appState.exportSettings.videoCodec) {
                                ForEach(VideoCodec.allCases) { item in
                                    Text(item.label).tag(item)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                    }

                    HStack(spacing: 16) {
                        // Resolution
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rozlišení")
                                .font(.caption2)
                                .foregroundColor(.gray)

                            Picker("", selection: $appState.exportSettings.resolution) {
                                ForEach(ExportResolution.allCases) { item in
                                    Text(item.label).tag(item)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                         
                        // Video quality
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kvalita videa")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Picker("", selection: $appState.exportSettings.qualityPreset) {
                                ForEach(QualityPreset.allCases) { item in
                                    Text(item.label).tag(item)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            
                            Text(appState.exportSettings.qualityPreset.bitrateLabel)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                    }

                    if appState.exportSettings.resolution == .custom || appState.exportSettings.qualityPreset == .custom {
                        HStack(spacing: 16) {
                            if appState.exportSettings.resolution == .custom {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Vlastní šířka")
                                        .font(.caption2)
                                        .foregroundColor(.gray)

                                    TextField("3840", value: $appState.exportSettings.customWidth, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Vlastní výška")
                                        .font(.caption2)
                                        .foregroundColor(.gray)

                                    TextField("1920", value: $appState.exportSettings.customHeight, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }

                            if appState.exportSettings.qualityPreset == .custom {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Video bitrate (Mbps)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)

                                    TextField("40", value: $appState.exportSettings.customVideoBitrateMbps, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                     
                    HStack(spacing: 16) {
                        // Audio Mode
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audio")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Picker("", selection: $appState.exportSettings.audioMode) {
                                ForEach(AudioMode.allCases) { item in
                                    Text(item.label).tag(item)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        // Framerate
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Snímková frekvence")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Picker("", selection: $appState.exportSettings.frameRateMode) {
                                ForEach(FrameRateMode.allCases) { item in
                                    Text(item.label).tag(item)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Audio bitrate
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
                            .frame(maxWidth: .infinity)
                            .disabled(appState.exportSettings.audioMode == .keepOriginal || appState.exportSettings.audioMode == .noAudio)
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
                
                // Preview panel
                OutputPreviewCardView()
                    .frame(width: 250)
            }
        }
    }
}
