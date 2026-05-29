import SwiftUI

struct ValidationResultView: View {
    @EnvironmentObject var appState: AppState
    let result: ValidationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: result.hasWarnings ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(result.hasWarnings ? .orange : .green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.hasWarnings ? "Export dokončen s varováním" : "Výstup vytvořen úspěšně")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 8)
            
            // Warnings list
            if result.hasWarnings {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.orange)
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Technical Specs Card
            VStack(alignment: .leading, spacing: 10) {
                Text("Technické parametry výstupu:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                Group {
                    HStack {
                        Text("Video stream:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.videoOk ? "OK" : "Chybí")
                            .fontWeight(.semibold)
                            .foregroundColor(result.videoOk ? .green : .red)
                    }
                    
                    HStack {
                        Text("360° projekce:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.projectionOk ? "Ano (Equirectangular)" : "Ne")
                            .fontWeight(.semibold)
                            .foregroundColor(result.projectionOk ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Audio kanály:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(result.channels) ch (\(result.channels == 4 ? "Spatial" : "Standard"))")
                            .fontWeight(.semibold)
                            .foregroundColor(result.channels >= 4 ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Audio kodek:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.codec)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Délka:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.durationOk ? "OK (sedí se zdrojem)" : "Odlišná")
                            .fontWeight(.semibold)
                            .foregroundColor(result.durationOk ? .green : .orange)
                    }
                }
                .font(.caption)
            }
            .padding(14)
            .background(Color(red: 0.129, green: 0.137, blue: 0.149))
            .cornerRadius(10)
            
            // File Destination Path Info
            if let job = appState.currentJob ?? appState.lastCompletedJob {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Soubor:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(job.outputURL.lastPathComponent)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(job.outputURL.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            // Action button
            HStack {
                Spacer()
                Button("Zavřít") {
                    appState.showValidationDetails = false
                    appState.validationResult = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 440)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}
