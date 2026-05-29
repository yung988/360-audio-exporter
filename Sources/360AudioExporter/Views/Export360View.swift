import SwiftUI

struct Export360View: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header & Info Block
            VStack(alignment: .leading, spacing: 8) {
                Text("Vstupní 360° video")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let asset = appState.inputVideo {
                    MediaInfoCardView(
                        asset: asset,
                        mode: .export360Video,
                        allowedExtensions: ["mp4", "mov", "360", "insv"]
                    )
                } else {
                    MediaDropZoneView(
                        title: "Přetáhněte 360° video soubor sem nebo klikněte pro výběr",
                        allowedExtensions: ["mp4", "mov", "360", "insv"],
                        mode: .export360Video
                    )
                }
            }
            
            // Export Configuration Grid
            if appState.inputVideo != nil {
                ExportSettingsView()
            } else {
                Spacer()
                    .frame(height: 120)
            }
            
            Spacer()
            
            // Footer (Destination Folder & Action button)
            VStack(spacing: 12) {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack {
                    // Destination Path Selector
                    HStack(spacing: 8) {
                        Text("Cíl exportu")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Text(appState.exportSettings.destinationFolder?.path ?? (appState.inputVideo != nil ? "Stejná složka jako vstup" : "Vyberte složku..."))
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
                    
                    // Spustit export Action
                    Button(action: {
                        appState.startExport()
                    }) {
                        Text("Spustit export")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(appState.inputVideo == nil ? Color.blue.opacity(0.4) : Color(red: 0.114, green: 0.380, blue: 0.882))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(appState.inputVideo == nil)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}
