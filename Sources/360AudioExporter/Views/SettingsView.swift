import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Orbit 360 uses ffmpeg for export and ffprobe for media inspection. The app looks for them automatically, but you can choose custom binary paths here.")
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)

            if !appState.isFfmpegAvailable || !appState.isFfprobeAvailable {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "terminal.fill")
                            .foregroundColor(.orange)
                        Text("ffmpeg / ffprobe is missing")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text("You can use bundled binaries or choose local ffmpeg and ffprobe files manually. Homebrew is optional.")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("Option 1: download an ffmpeg/ffprobe build, unzip it, and choose the binaries below.\nOption 2: if you use Homebrew, run: brew install ffmpeg")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineSpacing(3)

                    Text("brew install ffmpeg")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.green)
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(6)

                    HStack {
                        Button("Open ffmpeg.org") {
                            if let url = URL(string: "https://ffmpeg.org/download.html") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Text("After installing, restart the app or set the paths manually below.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(14)
                .background(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(10)
            }
            
            VStack(spacing: 16) {
                // ffmpeg path block
                VStack(alignment: .leading, spacing: 8) {
                    Text("ffmpeg path")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("/opt/homebrew/bin/ffmpeg", text: $appState.ffmpegPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        
                        Button("Browse...") {
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
                            Text("ffmpeg is available")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("No binary exists at this path")
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
                    Text("ffprobe path")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("/opt/homebrew/bin/ffprobe", text: $appState.ffprobePath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        
                        Button("Browse...") {
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
                            Text("ffprobe is available")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("No binary exists at this path")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(16)
                .background(Color(red: 0.129, green: 0.137, blue: 0.149))
                .cornerRadius(8)
            }
            
            Button("Save Settings") {
                appState.saveBinaryPaths()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding(32)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}
