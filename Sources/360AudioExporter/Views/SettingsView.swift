import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Nastavení")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Pro fungování exportů aplikace vyžaduje správně nakonfigurované binární soubory ffmpeg a ffprobe. Aplikace se je pokouší vyhledat v běžných systémových cestách automaticky.")
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
            
            VStack(spacing: 16) {
                // ffmpeg path block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cesta k ffmpeg")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("/opt/homebrew/bin/ffmpeg", text: $appState.ffmpegPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        
                        Button("Procházet...") {
                            if let selected = FileAccessService.selectFile(allowedExtensions: []) {
                                appState.ffmpegPath = selected.path
                                appState.saveBinaryPaths()
                            }
                        }
                    }
                    
                    HStack {
                        if appState.isFfmpegAvailable {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("ffmpeg je dostupný")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Binárka na této cestě neexistuje")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(16)
                .background(Color(red: 0.129, green: 0.137, blue: 0.149))
                .cornerRadius(8)
                
                // ffprobe path block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cesta k ffprobe")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("/opt/homebrew/bin/ffprobe", text: $appState.ffprobePath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        
                        Button("Procházet...") {
                            if let selected = FileAccessService.selectFile(allowedExtensions: []) {
                                appState.ffprobePath = selected.path
                                appState.saveBinaryPaths()
                            }
                        }
                    }
                    
                    HStack {
                        if appState.isFfprobeAvailable {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("ffprobe je dostupný")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Binárka na této cestě neexistuje")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(16)
                .background(Color(red: 0.129, green: 0.137, blue: 0.149))
                .cornerRadius(8)
            }
            
            Button("Uložit nastavení") {
                appState.saveBinaryPaths()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding(32)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}
