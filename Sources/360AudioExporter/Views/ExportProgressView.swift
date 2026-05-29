import SwiftUI

struct ExportProgressView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(appState.exportProgress?.stage ?? "Export")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .textCase(.uppercase)

                    Text(appState.exportProgress?.message ?? "Exportuji...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Progress indicator
                if let pct = appState.exportProgress?.percentage {
                    VStack(spacing: 8) {
                        ProgressView(value: pct)
                            .progressViewStyle(LinearProgressViewStyle())
                            .accentColor(.blue)
                        
                        HStack {
                            Text(String(format: "%.0f %%", pct * 100))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if let speed = appState.exportProgress?.speed {
                                Text("Rychlost: \(speed)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                // Time tracker details
                if let current = appState.exportProgress?.currentTime, let total = appState.exportProgress?.totalDuration {
                    VStack(spacing: 4) {
                        Text("Zpracováno: \(TimecodeParser.format(seconds: current)) / \(TimecodeParser.format(seconds: total))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)

                        if let remaining = appState.exportProgress?.estimatedRemainingSeconds {
                            Text("Odhad do konce: \(TimecodeParser.formatDuration(seconds: remaining))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                if let detail = appState.exportProgress?.detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                Button("Zrušit export") {
                    appState.cancelExport()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(28)
            .frame(width: 420)
            .background(Color(red: 0.129, green: 0.137, blue: 0.149))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
