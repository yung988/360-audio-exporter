import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation
            SidebarView(showSettings: $showSettings)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Main workspace content
            VStack(spacing: 0) {
                // Dependency notification banner
                if !appState.isFfmpegAvailable || !appState.isFfprobeAvailable {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.amberColor)
                        Text("Varování: chybí ffmpeg nebo ffprobe. Jděte do Nastavení a zkontrolujte cesty k binárkám.")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Přejít do nastavení") {
                            showSettings = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.2))
                    .border(Color.orange.opacity(0.3), width: 1)
                }
                
                // Active Error Banner
                if let errorMsg = appState.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                        Text(errorMsg)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { appState.errorMessage = nil }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.2))
                    .border(Color.red.opacity(0.3), width: 1)
                }
                
                // Content Views
                Group {
                    if showSettings {
                        SettingsView()
                    } else {
                        switch appState.selectedMode {
                        case .export360Video:
                            Export360View()
                        case .attachSpatialAudio:
                            AttachSpatialAudioView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(red: 0.086, green: 0.090, blue: 0.102))
        }
        .frame(minWidth: 960, minHeight: 660)
        .overlay(
            Group {
                if appState.isExporting {
                    ExportProgressView()
                }
            }
        )
        .sheet(isPresented: $appState.showValidationDetails) {
            if let result = appState.validationResult {
                ValidationResultView(result: result)
            }
        }
    }
}

extension Color {
    static let amberColor = Color(red: 1.0, green: 0.75, blue: 0.0)
}
